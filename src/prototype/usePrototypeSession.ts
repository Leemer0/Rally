"use client";

import { useCallback, useState } from "react";

import {
  prototypeAuthGateway,
  type PrototypeAuthSession,
} from "@/prototype/auth";
import { getVenue } from "@/prototype/data";
import {
  DEFAULT_PROTOTYPE_PROFILE,
  type ArrivalWindow,
  type AuthProvider,
  type GenderIdentity,
  type InterestedIn,
  type PrototypePlan,
  type PrototypeProfile,
  type PrototypeScreen,
} from "@/prototype/types";

const FIRST_NAME_MAX_LENGTH = 40;

export function usePrototypeSession() {
  const [screen, setScreen] = useState<PrototypeScreen>("welcome");
  const [, setHistory] = useState<PrototypeScreen[]>([]);
  const [profile, setProfile] = useState<PrototypeProfile>(
    DEFAULT_PROTOTYPE_PROFILE,
  );
  const [authSession, setAuthSession] = useState<PrototypeAuthSession | null>(
    null,
  );
  const [authLoading, setAuthLoading] = useState<AuthProvider | null>(null);
  const [nameError, setNameError] = useState<string | null>(null);
  const [selectedVenueId, setSelectedVenueId] = useState("track-field");
  const [arrivalWindow, setArrivalWindow] =
    useState<ArrivalWindow>("9:00–10:00 PM");
  const [groupSize, setGroupSizeState] = useState(2);
  const [plan, setPlan] = useState<PrototypePlan | null>(null);
  const [checkedInVenueId, setCheckedInVenueId] = useState<string | null>(null);
  const [offerRedeemed, setOfferRedeemed] = useState(false);

  const navigate = useCallback((nextScreen: PrototypeScreen) => {
    setScreen((currentScreen) => {
      setHistory((currentHistory) => [...currentHistory, currentScreen]);
      return nextScreen;
    });
  }, []);

  const goBack = useCallback(() => {
    setHistory((currentHistory) => {
      const previousScreen = currentHistory.at(-1);
      if (previousScreen) {
        setScreen(previousScreen);
        return currentHistory.slice(0, -1);
      }
      return currentHistory;
    });
  }, []);

  const continueWithAuth = useCallback(
    async (provider: AuthProvider) => {
      setAuthLoading(provider);
      const session = await prototypeAuthGateway.continueWith(provider);
      setAuthSession(session);
      setAuthLoading(null);
      navigate("onboarding_name");
    },
    [navigate],
  );

  const setFirstName = useCallback((firstName: string) => {
    setNameError(null);
    setProfile((current) => ({
      ...current,
      firstName: firstName.slice(0, FIRST_NAME_MAX_LENGTH),
    }));
  }, []);

  const submitName = useCallback(() => {
    const trimmedName = profile.firstName.trim();
    if (!trimmedName) {
      setNameError("Please enter your first name");
      return;
    }
    setProfile((current) => ({ ...current, firstName: trimmedName }));
    navigate("onboarding_age");
  }, [navigate, profile.firstName]);

  const setAge = useCallback((age: number) => {
    setProfile((current) => ({
      ...current,
      age: Math.min(40, Math.max(19, age)),
    }));
  }, []);

  const setGenderIdentity = useCallback((genderIdentity: GenderIdentity) => {
    setProfile((current) => ({ ...current, genderIdentity }));
  }, []);

  const setGenderSelfDescription = useCallback(
    (genderSelfDescription: string) => {
      setProfile((current) => ({
        ...current,
        genderSelfDescription: genderSelfDescription.slice(0, 50),
      }));
    },
    [],
  );

  const setInterestedIn = useCallback((interestedIn: InterestedIn) => {
    setProfile((current) => ({ ...current, interestedIn: [interestedIn] }));
  }, []);

  const selectVenue = useCallback(
    (venueId: string) => setSelectedVenueId(venueId),
    [],
  );

  const viewVenue = useCallback(
    (venueId: string) => {
      setSelectedVenueId(venueId);
      navigate("venue_detail");
    },
    [navigate],
  );

  const startRsvp = useCallback(
    (venueId: string) => {
      const venue = getVenue(venueId);
      setSelectedVenueId(venueId);
      setArrivalWindow(
        plan?.venueId === venueId
          ? plan.arrivalWindow
          : (venue.arrivalWindows[0] ?? "9:00–10:00 PM"),
      );
      setGroupSizeState(plan?.venueId === venueId ? plan.groupSize : 2);
      navigate("rsvp_arrival");
    },
    [navigate, plan],
  );

  const setGroupSize = useCallback((nextGroupSize: number) => {
    setGroupSizeState(Math.min(8, Math.max(1, nextGroupSize)));
  }, []);

  const confirmPlan = useCallback(() => {
    setPlan({
      venueId: selectedVenueId,
      arrivalWindow,
      groupSize,
      dateLabel: "Tonight · July 14",
    });
    navigate("rsvp_success");
  }, [arrivalWindow, groupSize, navigate, selectedVenueId]);

  const cancelPlan = useCallback(() => setPlan(null), []);

  const startCheckin = useCallback(
    (venueId?: string) => {
      if (venueId) setSelectedVenueId(venueId);
      setOfferRedeemed(false);
      navigate("checkin_intro");
    },
    [navigate],
  );

  const completeCheckin = useCallback(() => {
    setCheckedInVenueId(selectedVenueId);
    navigate("checkin_success");
  }, [navigate, selectedVenueId]);

  const redeemOffer = useCallback(() => {
    setOfferRedeemed(true);
    navigate("redeemed");
  }, [navigate]);

  const resetPrototype = useCallback(() => {
    setScreen("welcome");
    setHistory([]);
    setProfile(DEFAULT_PROTOTYPE_PROFILE);
    setAuthSession(null);
    setPlan(null);
    setCheckedInVenueId(null);
    setOfferRedeemed(false);
    setSelectedVenueId("track-field");
  }, []);

  return {
    arrivalWindow,
    authLoading,
    authSession,
    cancelPlan,
    checkedInVenueId,
    completeCheckin,
    confirmPlan,
    continueWithAuth,
    goBack,
    groupSize,
    nameError,
    navigate,
    offerRedeemed,
    plan,
    profile,
    redeemOffer,
    resetPrototype,
    screen,
    selectedVenueId,
    selectVenue,
    setAge,
    setArrivalWindow,
    setFirstName,
    setGenderIdentity,
    setGenderSelfDescription,
    setGroupSize,
    setInterestedIn,
    startCheckin,
    startRsvp,
    submitName,
    viewVenue,
  };
}
