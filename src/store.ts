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
