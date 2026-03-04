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
