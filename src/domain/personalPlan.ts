import { addDays, parse, isValid } from "date-fns";
import type { MonthlyPayout, TrainingRow } from "../store";

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
