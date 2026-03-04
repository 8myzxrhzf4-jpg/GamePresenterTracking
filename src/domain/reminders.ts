import { isBefore } from "date-fns";
export function reminderStatus(dueDate: Date) {
  const now = new Date();
  if (isBefore(dueDate, now)) return "overdue";
  const diff = Math.ceil((dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
  if (diff <= 7) return "upcoming";
  return "ok";
}
