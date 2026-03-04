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
