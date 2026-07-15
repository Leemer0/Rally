export type AuthProvider = "email" | "google";

export type GenderIdentity =
  "woman" | "man" | "non_binary" | "self_describe" | "prefer_not_to_say";

export type InterestedIn = "women" | "men" | "everyone";

export type PrototypeScreen =
  | "welcome"
  | "auth"
  | "onboarding_name"
  | "onboarding_age"
  | "onboarding_gender"
  | "onboarding_interested"
  | "onboarding_complete"
  | "explore"
  | "list"
  | "profile"
  | "venue_detail"
  | "rsvp_arrival"
  | "rsvp_group"
  | "rsvp_confirm"
  | "rsvp_success"
  | "checkin_intro"
  | "checkin_scan"
  | "checkin_location"
  | "checkin_success"
  | "offer"
  | "redeem_confirm"
  | "redeemed";

export type ArrivalWindow =
  | "8:00–9:00 PM"
  | "9:00–10:00 PM"
  | "10:00–11:00 PM"
  | "11:00 PM–12:00 AM"
  | "After midnight";

export type PrototypePlan = {
  venueId: string;
  arrivalWindow: ArrivalWindow;
  groupSize: number;
  dateLabel: string;
};

export type PrototypeProfile = {
  firstName: string;
  age: number;
  genderIdentity: GenderIdentity | null;
  genderSelfDescription: string;
  interestedIn: InterestedIn[];
};

export const DEFAULT_PROTOTYPE_PROFILE: PrototypeProfile = {
  firstName: "",
  age: 25,
  genderIdentity: null,
  genderSelfDescription: "",
  interestedIn: [],
};
