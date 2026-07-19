export const overviewMetrics = [
  { label: "Current plans", value: "46", change: "+9", note: "vs. previous Friday" },
  { label: "Verified check-ins", value: "31", change: "+6", note: "vs. previous Friday" },
  { label: "Plan-to-check-in", value: "67%", change: "+4 pts", note: "matching tonight’s plans" },
  { label: "Returning visitors", value: "9", change: "29%", note: "of verified check-ins" },
];

export const weeklyActivity = [
  { day: "Mon", views: 112, plans: 14, checkIns: 8 },
  { day: "Tue", views: 138, plans: 18, checkIns: 12 },
  { day: "Wed", views: 164, plans: 22, checkIns: 15 },
  { day: "Thu", views: 224, plans: 31, checkIns: 21 },
  { day: "Fri", views: 386, plans: 46, checkIns: 31 },
  { day: "Sat", views: 342, plans: 41, checkIns: 30 },
  { day: "Sun", views: 126, plans: 16, checkIns: 9 },
];

export const checkInTimeDistribution = [
  { label: "8–9 PM", shortLabel: "8", count: 8 },
  { label: "9–10 PM", shortLabel: "9", count: 19 },
  { label: "10–11 PM", shortLabel: "10", count: 34 },
  { label: "11 PM–12 AM", shortLabel: "11", count: 37 },
  { label: "12–1 AM", shortLabel: "12", count: 20 },
  { label: "After 1 AM", shortLabel: "1+", count: 8 },
];

export const visitorMix = [
  { label: "First-time visitors", value: 88, percent: 70 },
  { label: "Returning visitors", value: 38, percent: 30 },
];

export const tonightVisitorMix = [
  { label: "First-time", value: 22, percent: 71 },
  { label: "Returning", value: 9, percent: 29 },
];

export const visitorHistory = [
  { period: "Jun 15", firstTime: 70, returning: 22 },
  { period: "Jun 22", firstTime: 74, returning: 24 },
  { period: "Jun 29", firstTime: 80, returning: 29 },
  { period: "Jul 6", firstTime: 84, returning: 34 },
  { period: "Jul 13", firstTime: 88, returning: 38 },
];

export const offers = [
  {
    name: "Free cover with Outly before 10 PM",
    status: "Active",
    window: "Fri-Sat · 8:00-10:00 PM",
    unlocked: 24,
    updated: "Today",
  },
  {
    name: "Complimentary coat check",
    status: "Draft",
    window: "Thu · 9:00-11:00 PM",
    unlocked: 0,
    updated: "Jul 17",
  },
];
