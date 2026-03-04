# --- config ---
REPO_DIR="."
BRANCH="feature/local-scaffold-dashboard"
PR_TITLE="Add local testing scaffold with CSV imports and performance dashboard"
PR_BODY="This PR adds a local-first React+TypeScript scaffold for testing and debugging before Firebase migration.

Includes:
- CSV import UI for Monthly Payouts, Training Sessions, Tickets
- Local store/state for imported data
- Probation tracking (Onboarding/PG30/PG60/PG90)
- Personal Plan goals + reminder statuses (30/60/90)
- Team manager coaching compliance view
- Basic dashboard tables and styling"

# --- enter repo ---
cd "$REPO_DIR" || exit 1

# --- create branch ---
git checkout main
git pull origin main
git checkout -b "$BRANCH"

# --- ensure frontend scaffold exists (non-destructive) ---
if [ ! -f "package.json" ]; then
  npm create vite@latest . -- --template react-ts
fi

npm install
npm install papaparse date-fns recharts zustand zod
npm install -D @types/papaparse

mkdir -p src/pages src/domain

cat > src/main.tsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > src/App.tsx <<'EOF'
import { useState } from "react";
import { ImportPage } from "./pages/ImportPage";
import { DashboardPage } from "./pages/DashboardPage";

export default function App() {
  const [ready, setReady] = useState(false);
  return (
    <div className="app">
      <header><h1>Game Presenter Tracker (Local)</h1></header>
      {!ready ? <ImportPage onReady={() => setReady(true)} /> : <DashboardPage />}
    </div>
  );
}
EOF

cat > src/store.ts <<'EOF'
import { create } from "zustand";

export type MonthlyPayout = {
  dealer: string;
  team: string;
  scheduleGroup: string;
  daysWorked: number | null;
  countedMistakes: number | null;
  totalGames: number | null;
};

export type TrainingRow = {
  dealer: string;
  team: string;
  date: string;
  trainingTypes: string[];
  providedBy: string;
};

export type TicketRow = {
  dealer: string;
  issue: string;
  gameCategory: string;
  shiftDate: string;
};

type State = {
  payouts: MonthlyPayout[];
  trainings: TrainingRow[];
  tickets: TicketRow[];
  setPayouts: (v: MonthlyPayout[]) => void;
  setTrainings: (v: TrainingRow[]) => void;
  setTickets: (v: TicketRow[]) => void;
};

export const useAppStore = create<State>((set) => ({
  payouts: [],
  trainings: [],
  tickets: [],
  setPayouts: (payouts) => set({ payouts }),
  setTrainings: (trainings) => set({ trainings }),
  setTickets: (tickets) => set({ tickets }),
}));
EOF

cat > src/pages/ImportPage.tsx <<'EOF'
import Papa from "papaparse";
import { useAppStore } from "../store";

type Props = { onReady: () => void };

export function ImportPage({ onReady }: Props) {
  const { setPayouts, setTrainings, setTickets, payouts, trainings, tickets } = useAppStore();

  const parseFile = (file: File, kind: "payouts" | "trainings" | "tickets") => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (res) => {
        const rows = res.data as any[];
        if (kind === "payouts") {
          setPayouts(rows.map((r) => ({
            dealer: r["Dealer"]?.trim(),
            team: r["Team"]?.trim(),
            scheduleGroup: r["Schedule group"]?.trim(),
            daysWorked: Number(r["Days worked"]) || null,
            countedMistakes: Number(r["Counted dealer mistakes"]) || null,
            totalGames: Number(r["Total games"]) || null,
          })));
        }
        if (kind === "trainings") {
          setTrainings(rows.map((r) => ({
            dealer: r["Dealer"]?.trim(),
            team: r["Team"]?.trim(),
            date: r["Date"]?.trim(),
            trainingTypes: String(r["Training types"] || "").split(",").map((x) => x.trim()).filter(Boolean),
            providedBy: r["Provided by"]?.trim(),
          })));
        }
        if (kind === "tickets") {
          setTickets(rows.map((r) => ({
            dealer: r["Dealer"]?.trim(),
            issue: r["Issue"]?.trim(),
            gameCategory: r["Game category"]?.trim(),
            shiftDate: r["Shift date"]?.trim(),
          })));
        }
      },
    });
  };

  return (
    <div>
      <h2>Import CSVs</h2>
      <label>Monthly Payouts CSV <input type="file" accept=".csv" onChange={(e) => e.target.files?.[0] && parseFile(e.target.files[0], "payouts")} /></label>
      <label>Training CSV <input type="file" accept=".csv" onChange={(e) => e.target.files?.[0] && parseFile(e.target.files[0], "trainings")} /></label>
      <label>Tickets CSV <input type="file" accept=".csv" onChange={(e) => e.target.files?.[0] && parseFile(e.target.files[0], "tickets")} /></label>
      <p>Payouts: {payouts.length} | Trainings: {trainings.length} | Tickets: {tickets.length}</p>
      <button disabled={!payouts.length || !trainings.length || !tickets.length} onClick={onReady}>Open Dashboard</button>
    </div>
  );
}
EOF

cat > src/domain/rules.ts <<'EOF'
import { addDays, differenceInCalendarDays, parse, isValid } from "date-fns";
import { TrainingRow, MonthlyPayout, TicketRow } from "../store";

const COACHING_TYPES = ["misscan", "extra card related mistakes", "many mistake makers", "spin technique"];

export function parseTrainingDate(input: string): Date | null {
  const d = parse(input, "dd.MM.yyyy", new Date());
  return isValid(d) ? d : null;
}
export function deriveHireDateFromDaysWorked(daysWorked: number | null): Date | null {
  if (!daysWorked && daysWorked !== 0) return null;
  return addDays(new Date(), -daysWorked);
}
export function getProbationStatus(gp: MonthlyPayout, trainings: TrainingRow[]) {
  const hireDate = deriveHireDateFromDaysWorked(gp.daysWorked);
  if (!hireDate) return null;
  const byDealer = trainings.filter((t) => t.dealer === gp.dealer);
  const hasTypeByDay = (type: string, day: number) => byDealer.some((t) => {
    const dt = parseTrainingDate(t.date); if (!dt) return false;
    const age = differenceInCalendarDays(dt, hireDate);
    return age <= day && t.trainingTypes.map((x) => x.toLowerCase()).includes(type.toLowerCase());
  });
  return { onboarding15: hasTypeByDay("Onboarding", 15), pg30: hasTypeByDay("Probationary Goals 30", 30), pg60: hasTypeByDay("Probationary Goals 60", 60), pg90: hasTypeByDay("Probationary Goals 90", 90) };
}
export function getManagerCoachingCompliance(gp: MonthlyPayout, trainings: TrainingRow[], tickets: TicketRow[]) {
  const mistakes = tickets.filter((t) => t.dealer === gp.dealer).length;
  const required = Math.floor(mistakes / 5);
  const coachingCount = trainings.filter((t) => t.dealer === gp.dealer).flatMap((t) => t.trainingTypes.map((x) => x.toLowerCase().trim())).filter((x) => COACHING_TYPES.includes(x)).length;
  return { mistakes, required, coachingCount, compliant: coachingCount >= required };
}
EOF

cat > src/domain/personalPlan.ts <<'EOF'
import { addDays, parse, isValid } from "date-fns";
import { MonthlyPayout, TrainingRow } from "../store";

function parseTrainingDate(input: string): Date | null { const d = parse(input, "dd.MM.yyyy", new Date()); return isValid(d) ? d : null; }
function hireDateFromDaysWorked(daysWorked: number | null): Date | null { if (daysWorked == null) return null; return addDays(new Date(), -daysWorked); }
function getBand(daysWorked: number) { if (daysWorked >= 91 && daysWorked <= 120) return 700; if (daysWorked >= 121 && daysWorked <= 150) return 1100; if (daysWorked >= 151) return 1300; return null; }

export function getPersonalPlan(gp: MonthlyPayout, trainings: TrainingRow[]) {
  const hireDate = hireDateFromDaysWorked(gp.daysWorked); if (!hireDate || gp.daysWorked == null) return null;
  const planTraining = trainings.filter((t) => t.dealer === gp.dealer).find((t) => t.trainingTypes.some((x) => x.toLowerCase().includes("personal plan"))); if (!planTraining) return null;
  const start = parseTrainingDate(planTraining.date); if (!start) return null;
  const endGoal = getBand(gp.daysWorked); if (!endGoal) return null;
  const startGoal = endGoal === 1100 ? 700 : endGoal === 1300 ? 1100 : 500;
  const goal30 = startGoal, goal60 = Math.round((startGoal + endGoal) / 2), goal90 = endGoal;
  return { goal30, goal60, goal90, due30: addDays(start, 30), due60: addDays(start, 60), due90: addDays(start, 90) };
}
EOF

cat > src/domain/reminders.ts <<'EOF'
import { isBefore } from "date-fns";
export function reminderStatus(dueDate: Date) {
  const now = new Date();
  if (isBefore(dueDate, now)) return "overdue";
  const diff = Math.ceil((dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (diff <= 7) return "upcoming";
  return "ok";
}
EOF

cat > src/pages/DashboardPage.tsx <<'EOF'
import { useMemo, useState } from "react";
import { useAppStore } from "../store";
import { getProbationStatus, getManagerCoachingCompliance } from "../domain/rules";
import { getPersonalPlan } from "../domain/personalPlan";
import { reminderStatus } from "../domain/reminders";

export function DashboardPage() {
  const { payouts, trainings, tickets } = useAppStore();
  const [teamFilter, setTeamFilter] = useState("");

  const filtered = useMemo(() => payouts.filter((p) => !teamFilter || (p.team || "").toLowerCase().includes(teamFilter.toLowerCase())), [payouts, teamFilter]);
  const probationRows = useMemo(() => filtered.map((gp) => ({ dealer: gp.dealer, team: gp.team, status: getProbationStatus(gp, trainings) })).filter((x) => x.status), [filtered, trainings]) as any[];
  const personalPlans = useMemo(() => filtered.map((gp) => ({ dealer: gp.dealer, team: gp.team, plan: getPersonalPlan(gp, trainings) })).filter((x) => x.plan), [filtered, trainings]) as any[];
  const complianceRows = useMemo(() => filtered.map((gp) => ({ dealer: gp.dealer, team: gp.team, ...getManagerCoachingCompliance(gp, trainings, tickets) })), [filtered, trainings, tickets]);

  return (
    <div>
      <h2>Dashboard</h2>
      <input placeholder="Filter by team manager..." value={teamFilter} onChange={(e) => setTeamFilter(e.target.value)} />
      <h3>Probation</h3>
      <table><thead><tr><th>Dealer</th><th>Team</th><th>Onb15</th><th>PG30</th><th>PG60</th><th>PG90</th></tr></thead><tbody>
      {probationRows.slice(0,40).map((r:any)=><tr key={r.dealer}><td>{r.dealer}</td><td>{r.team}</td><td>{String(r.status.onboarding15)}</td><td>{String(r.status.pg30)}</td><td>{String(r.status.pg60)}</td><td>{String(r.status.pg90)}</td></tr>)}
      </tbody></table>

      <h3>Personal Plans + Reminders</h3>
      <table><thead><tr><th>Dealer</th><th>Team</th><th>30</th><th>60</th><th>90</th><th>R30</th><th>R60</th><th>R90</th></tr></thead><tbody>
      {personalPlans.slice(0,40).map((r:any)=><tr key={r.dealer}><td>{r.dealer}</td><td>{r.team}</td><td>{r.plan.goal30}</td><td>{r.plan.goal60}</td><td>{r.plan.goal90}</td><td>{reminderStatus(r.plan.due30)}</td><td>{reminderStatus(r.plan.due60)}</td><td>{reminderStatus(r.plan.due90)}</td></tr>)}
      </tbody></table>

      <h3>Manager Coaching Compliance</h3>
      <table><thead><tr><th>Dealer</th><th>Team</th><th>Mistakes</th><th>Req</th><th>Coaching</th><th>Compliant</th></tr></thead><tbody>
      {complianceRows.slice(0,40).map((r:any)=><tr key={r.dealer}><td>{r.dealer}</td><td>{r.team}</td><td>{r.mistakes}</td><td>{r.required}</td><td>{r.coachingCount}</td><td>{String(r.compliant)}</td></tr>)}
      </tbody></table>
    </div>
  );
}
EOF

cat > src/styles.css <<'EOF'
body { font-family: Arial, sans-serif; margin: 0; background: #f7f7f9; }
.app { max-width: 1200px; margin: 0 auto; padding: 20px; }
header { margin-bottom: 16px; }
label { display: block; margin: 10px 0; }
input { margin: 6px 0; padding: 6px; }
button { padding: 8px 12px; cursor: pointer; }
table { width: 100%; border-collapse: collapse; margin: 10px 0 20px; background: #fff; }
th, td { border: 1px solid #ddd; padding: 6px; font-size: 12px; text-align: left; }
EOF

# --- commit ---
git add .
git commit -m "Add local scaffold, CSV imports, probation/personal plan tracking, reminders, and manager compliance dashboard"

# --- push ---
git push -u origin "$BRANCH"

# --- open PR (requires gh CLI auth) ---
gh pr create --base main --head "$BRANCH" --title "$PR_TITLE" --body "$PR_BODY"

echo "PR created."echo "Script created. Replace this line with full script content."
