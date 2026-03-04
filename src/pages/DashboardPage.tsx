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
