export type VenueStatus = "Approved" | "Pending" | "Paused";
export type UserStatus = "Active" | "Paused" | "Deletion requested";
export type PartnerOfferStatus = "Draft" | "Ready" | "Active";

export const adminOverviewMetrics = [
  { label: "Approved venues", value: "4", note: "2 paid, 2 free" },
  { label: "Plans tonight", value: "214", note: "Across Toronto network" },
  { label: "Verified check-ins", value: "146", note: "68% of plans" },
  { label: "90-day return rate", value: "27%", note: "Verified visitors" },
];

export const networkActivity = [
  { day: "Mon", plans: 82, checkIns: 49 },
  { day: "Tue", plans: 94, checkIns: 57 },
  { day: "Wed", plans: 118, checkIns: 76 },
  { day: "Thu", plans: 156, checkIns: 103 },
  { day: "Fri", plans: 214, checkIns: 146 },
  { day: "Sat", plans: 238, checkIns: 169 },
  { day: "Sun", plans: 91, checkIns: 52 },
];

export const checkInDistribution = [
  { label: "8 PM", count: 18 },
  { label: "9 PM", count: 39 },
  { label: "10 PM", count: 64 },
  { label: "11 PM", count: 76 },
  { label: "12 AM", count: 52 },
  { label: "1 AM", count: 24 },
];

export const returnCohorts = [
  { label: "First visit", value: 73 },
  { label: "Returned once", value: 19 },
  { label: "Returned 2+ times", value: 8 },
];

export const venues = [
  {
    id: "morrow-house",
    name: "Morrow House",
    neighborhood: "Ossington",
    status: "Approved" as VenueStatus,
    plan: "Outly Pro",
    tonight: 42,
    checkIns30d: 318,
    repeatRate: "31%",
    offer: "Free cover with Outly before 10 PM",
    contact: "ops@morrowhouse.example",
  },
  {
    id: "lantern-club",
    name: "Lantern Club",
    neighborhood: "King West",
    status: "Approved" as VenueStatus,
    plan: "Free",
    tonight: 36,
    checkIns30d: 274,
    repeatRate: "24%",
    offer: "No active offer",
    contact: "team@lanternclub.example",
  },
  {
    id: "juniper-common",
    name: "Juniper Common",
    neighborhood: "College",
    status: "Approved" as VenueStatus,
    plan: "Outly Pro",
    tonight: 31,
    checkIns30d: 226,
    repeatRate: "29%",
    offer: "Early arrival offer",
    contact: "hello@junipercommon.example",
  },
  {
    id: "civic-room",
    name: "Civic Room",
    neighborhood: "Chinatown",
    status: "Pending" as VenueStatus,
    plan: "Free",
    tonight: 0,
    checkIns30d: 0,
    repeatRate: "-",
    offer: "Draft",
    contact: "owner@civicroom.example",
  },
  {
    id: "northline-social",
    name: "Northline Social",
    neighborhood: "Ossington",
    status: "Approved" as VenueStatus,
    plan: "Free",
    tonight: 28,
    checkIns30d: 192,
    repeatRate: "22%",
    offer: "Coat check offer",
    contact: "venue@northlinesocial.example",
  },
  {
    id: "sidecar-hall",
    name: "Sidecar Hall",
    neighborhood: "College",
    status: "Paused" as VenueStatus,
    plan: "Free",
    tonight: 0,
    checkIns30d: 84,
    repeatRate: "18%",
    offer: "Paused",
    contact: "admin@sidecarhall.example",
  },
];

export const users = [
  { id: "U-2048", email: "li••@icloud.com", status: "Active" as UserStatus, is19Plus: true, gender: "Man", joined: "Jul 18", plans: 4, checkIns: 3, lastActive: "Today" },
  { id: "U-2039", email: "mi••@gmail.com", status: "Active" as UserStatus, is19Plus: true, gender: "Woman", joined: "Jul 17", plans: 2, checkIns: 2, lastActive: "Today" },
  { id: "U-2017", email: "sa••@outlook.com", status: "Active" as UserStatus, is19Plus: true, gender: "Another gender", joined: "Jul 14", plans: 5, checkIns: 4, lastActive: "Yesterday" },
  { id: "U-1984", email: "no••@gmail.com", status: "Paused" as UserStatus, is19Plus: true, gender: "Woman", joined: "Jul 9", plans: 1, checkIns: 0, lastActive: "Jul 12" },
  { id: "U-1962", email: "al••@icloud.com", status: "Deletion requested" as UserStatus, is19Plus: true, gender: "Man", joined: "Jul 6", plans: 3, checkIns: 2, lastActive: "Jul 11" },
  { id: "U-1921", email: "ta••@proton.me", status: "Active" as UserStatus, is19Plus: true, gender: "Another gender", joined: "Jun 29", plans: 8, checkIns: 7, lastActive: "Jul 18" },
];

export const partners = [
  { id: "northline", name: "Northline", category: "Transportation", contact: "partnerships@northline.example", status: "Active", offers: 1, budget: "$4,000" },
  { id: "afterglow-tickets", name: "Afterglow Tickets", category: "Entertainment", contact: "brand@afterglow.example", status: "Active", offers: 1, budget: "$7,500" },
  { id: "side-street-eats", name: "Side Street Eats", category: "Food delivery", contact: "growth@sidestreeteats.example", status: "Onboarding", offers: 1, budget: "Not set" },
];

export const partnerOffers = [
  { id: "ride-home-signup", partner: "Northline", name: "50% off your ride home", status: "Active" as PartnerOfferStatus, claim: "Verified check-in + new signup", venues: 3, claims: 86, ends: "Aug 31" },
  { id: "appetizer-check-in", partner: "Side Street Eats", name: "Free appetizer after check-in", status: "Ready" as PartnerOfferStatus, claim: "Verified venue check-in", venues: 0, claims: 0, ends: "Sep 14" },
  { id: "event-credit", partner: "Afterglow Tickets", name: "$10 event ticket credit", status: "Draft" as PartnerOfferStatus, claim: "Verified venue check-in", venues: 0, claims: 0, ends: "Not set" },
];

export const assignments = [
  { id: "A-104", offer: "50% off your ride home", partner: "Northline", venue: "Morrow House", status: "Active", window: "Fri-Sat, 9 PM-1 AM", claims: 38 },
  { id: "A-103", offer: "50% off your ride home", partner: "Northline", venue: "Lantern Club", status: "Active", window: "Fri-Sat, 9 PM-1 AM", claims: 27 },
  { id: "A-102", offer: "50% off your ride home", partner: "Northline", venue: "Juniper Common", status: "Active", window: "Fri-Sat, 9 PM-1 AM", claims: 21 },
  { id: "A-101", offer: "Free appetizer after check-in", partner: "Side Street Eats", venue: "Northline Social", status: "Awaiting venue", window: "Thu, 8 PM-10 PM", claims: 0 },
];

export const adminQueue = [
  { label: "Venue approval", detail: "Civic Room", href: "/admin/venues/civic-room", priority: "Review" },
  { label: "Account deletion", detail: "User U-1962", href: "/admin/users?q=U-1962", priority: "Due today" },
  { label: "Offer assignment", detail: "Side Street Eats", href: "/admin/assignments/new", priority: "Ready" },
];
