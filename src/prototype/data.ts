import type { ArrivalWindow } from "@/prototype/types";

export type AgeDistributionPoint = {
  age: number;
  intensity: number;
};

export type AgeDistribution = {
  status: "available" | "limited_data";
  minAge: 19;
  maxAge: 40;
  peakAge: number | null;
  points: AgeDistributionPoint[];
};

export type VenueActivity = "low" | "building" | "busy" | "peak";

export type PrototypeVenue = {
  id: string;
  name: string;
  neighbourhood: string;
  category: string;
  hours: string;
  address: string;
  goingCount: number;
  verifiedCount: number;
  expectedPeakTime: string;
  offer: string | null;
  offerDetails: string | null;
  description: string;
  activity: VenueActivity;
  marker: { left: number; top: number };
  markerArt: string;
  ageDistribution: AgeDistribution;
  arrivalWindows: ArrivalWindow[];
  distance: string;
};

function mockDistribution(peakAge: number, spread = 4): AgeDistribution {
  const points = Array.from({ length: 22 }, (_, index) => {
    const age = index + 19;
    const distance = age - peakAge;
    return {
      age,
      intensity: Number(
        Math.exp(-(distance * distance) / (2 * spread * spread)).toFixed(3),
      ),
    };
  });

  return { status: "available", minAge: 19, maxAge: 40, peakAge, points };
}

export const venues: PrototypeVenue[] = [
  {
    id: "track-field",
    name: "Track & Field",
    neighbourhood: "Ossington",
    category: "Games Bar",
    hours: "Open 5:00 PM–2:00 AM",
    address: "860 College St, Toronto",
    goingCount: 46,
    verifiedCount: 14,
    expectedPeakTime: "10:30 PM",
    offer: "Free cover before 10:00 PM",
    offerDetails: "One complimentary cover when you check in before 10:00 PM.",
    description:
      "Shuffleboard, bocce, and a big social room built for groups that actually want to mingle.",
    activity: "peak",
    marker: { left: 31, top: 42 },
    markerArt: "/venue-markers/track-field.png",
    ageDistribution: mockDistribution(27, 3.4),
    arrivalWindows: [
      "8:00–9:00 PM",
      "9:00–10:00 PM",
      "10:00–11:00 PM",
      "11:00 PM–12:00 AM",
      "After midnight",
    ],
    distance: "1.2 km",
  },
  {
    id: "lavelle",
    name: "Lavelle",
    neighbourhood: "King West",
    category: "Rooftop Lounge",
    hours: "Open until 2:00 AM",
    address: "627 King St W, Toronto",
    goingCount: 38,
    verifiedCount: 9,
    expectedPeakTime: "11:00 PM",
    offer: "Welcome drink before 10:30 PM",
    offerDetails: "One house welcome drink after a verified Outly check-in.",
    description:
      "A rooftop escape with a high-energy room, skyline views, and a late-night crowd.",
    activity: "busy",
    marker: { left: 57, top: 58 },
    markerArt: "/venue-markers/lavelle.png",
    ageDistribution: mockDistribution(29, 4.2),
    arrivalWindows: [
      "9:00–10:00 PM",
      "10:00–11:00 PM",
      "11:00 PM–12:00 AM",
      "After midnight",
    ],
    distance: "800 m",
  },
  {
    id: "baro",
    name: "Baro",
    neighbourhood: "King West",
    category: "Latin Restaurant & Bar",
    hours: "Open 5:00 PM–2:00 AM",
    address: "485 King St W, Toronto",
    goingCount: 24,
    verifiedCount: 6,
    expectedPeakTime: "9:30 PM",
    offer: null,
    offerDetails: null,
    description:
      "A warm multi-level space for dinner that rolls naturally into drinks and dancing.",
    activity: "building",
    marker: { left: 69, top: 33 },
    markerArt: "/venue-markers/baro.png",
    ageDistribution: mockDistribution(31, 4.8),
    arrivalWindows: [
      "8:00–9:00 PM",
      "9:00–10:00 PM",
      "10:00–11:00 PM",
      "11:00 PM–12:00 AM",
    ],
    distance: "650 m",
  },
  {
    id: "paris-texas",
    name: "Paris Texas",
    neighbourhood: "King West",
    category: "Dance Bar",
    hours: "Opening at 8:00 PM",
    address: "461 King St W, Toronto",
    goingCount: 17,
    verifiedCount: 0,
    expectedPeakTime: "11:30 PM",
    offer: "Free coat check",
    offerDetails: "Complimentary coat check with a verified Outly check-in.",
    description:
      "A western-inspired party bar with DJs, dancing, and a playful late-night atmosphere.",
    activity: "low",
    marker: { left: 45, top: 24 },
    markerArt: "/venue-markers/paris-texas.png",
    ageDistribution: {
      status: "limited_data",
      minAge: 19,
      maxAge: 40,
      peakAge: null,
      points: [],
    },
    arrivalWindows: [
      "9:00–10:00 PM",
      "10:00–11:00 PM",
      "11:00 PM–12:00 AM",
      "After midnight",
    ],
    distance: "500 m",
  },
];

export function getVenue(venueId: string) {
  return venues.find((venue) => venue.id === venueId) ?? venues[0];
}
