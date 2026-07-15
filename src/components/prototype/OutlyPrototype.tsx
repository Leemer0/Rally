"use client";

import { OutlyLogo } from "@/components/OutlyLogo";
import {
  CheckinIntroScreen,
  CheckinLocationScreen,
  CheckinScanScreen,
  CheckinSuccessScreen,
  OfferScreen,
  RedeemConfirmScreen,
  RedeemedScreen,
} from "@/components/prototype/CheckinScreens";
import { ExploreScreen } from "@/components/prototype/ExploreScreen";
import { ListScreen } from "@/components/prototype/ListScreen";
import {
  ChoiceRow,
  OnboardingScreen,
} from "@/components/prototype/OnboardingScreen";
import { PrototypeFrame } from "@/components/prototype/PrototypeFrame";
import { ProfileScreen } from "@/components/prototype/ProfileScreen";
import {
  RsvpArrivalScreen,
  RsvpConfirmScreen,
  RsvpGroupScreen,
  RsvpSuccessScreen,
} from "@/components/prototype/RsvpScreens";
import { TorontoSkyline } from "@/components/prototype/TorontoSkyline";
import { VenueDetailScreen } from "@/components/prototype/VenueDetailScreen";
import { Button } from "@/components/ui/Button";
import { Icon } from "@/components/ui/Icon";
import { Input } from "@/components/ui/Input";
import { getVenue } from "@/prototype/data";
import type { GenderIdentity, InterestedIn } from "@/prototype/types";
import { usePrototypeSession } from "@/prototype/usePrototypeSession";

const genderOptions: Array<{ label: string; value: GenderIdentity }> = [
  { label: "Woman", value: "woman" },
  { label: "Man", value: "man" },
  { label: "Non-binary", value: "non_binary" },
  { label: "Prefer to self-describe", value: "self_describe" },
  { label: "Prefer not to say", value: "prefer_not_to_say" },
];

const interestedOptions: Array<{ label: string; value: InterestedIn }> = [
  { label: "Women", value: "women" },
  { label: "Men", value: "men" },
  { label: "Everyone", value: "everyone" },
];

export function OutlyPrototype() {
  const session = usePrototypeSession();
  const selectedVenue = getVenue(session.selectedVenueId);
  const goToTab = (tab: "explore" | "list" | "profile") =>
    session.navigate(tab);

  return (
    <PrototypeFrame>
      {session.screen === "welcome" ? (
        <WelcomeScreen
          onGetStarted={() => session.navigate("auth")}
          onLogIn={() => session.navigate("auth")}
        />
      ) : null}

      {session.screen === "auth" ? (
        <AuthScreen
          loading={session.authLoading}
          onBack={session.goBack}
          onContinue={session.continueWithAuth}
        />
      ) : null}

      {session.screen === "onboarding_name" ? (
        <OnboardingScreen
          onBack={session.goBack}
          onNext={session.submitName}
          step={1}
          title="What’s your name?"
          description="Your first name stays private and is never shown in venue activity."
        >
          <Input
            autoComplete="given-name"
            error={session.nameError ?? undefined}
            label="First name"
            maxLength={40}
            onChange={(event) => session.setFirstName(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") session.submitName();
            }}
            placeholder="Enter your first name"
            value={session.profile.firstName}
          />
        </OnboardingScreen>
      ) : null}

      {session.screen === "onboarding_age" ? (
        <OnboardingScreen
          onBack={session.goBack}
          onNext={() => session.navigate("onboarding_gender")}
          step={2}
          title="How old are you?"
          description="Outly is for people 19 to 40."
        >
          <AgeSelector age={session.profile.age} onChange={session.setAge} />
        </OnboardingScreen>
      ) : null}

      {session.screen === "onboarding_gender" ? (
        <OnboardingScreen
          nextDisabled={!session.profile.genderIdentity}
          onBack={session.goBack}
          onNext={() => session.navigate("onboarding_interested")}
          step={3}
          title="How do you identify?"
        >
          <div className="grid gap-2.5">
            {genderOptions.map((option) => (
              <ChoiceRow
                key={option.value}
                label={option.label}
                onClick={() => session.setGenderIdentity(option.value)}
                selected={session.profile.genderIdentity === option.value}
              />
            ))}
          </div>
          {session.profile.genderIdentity === "self_describe" ? (
            <Input
              className="mt-4"
              label="How do you describe yourself?"
              onChange={(event) =>
                session.setGenderSelfDescription(event.target.value)
              }
              placeholder="Your words"
              value={session.profile.genderSelfDescription}
            />
          ) : null}
        </OnboardingScreen>
      ) : null}

      {session.screen === "onboarding_interested" ? (
        <OnboardingScreen
          nextDisabled={session.profile.interestedIn.length === 0}
          onBack={session.goBack}
          onNext={() => session.navigate("onboarding_complete")}
          step={4}
          title="Who are you interested in meeting?"
          description="This stays private. It won’t appear on venue pages."
        >
          <div className="grid gap-3">
            {interestedOptions.map((option) => (
              <ChoiceRow
                key={option.value}
                label={option.label}
                onClick={() => session.setInterestedIn(option.value)}
                selected={session.profile.interestedIn.includes(option.value)}
              />
            ))}
          </div>
        </OnboardingScreen>
      ) : null}

      {session.screen === "onboarding_complete" ? (
        <CompletionScreen
          firstName={session.profile.firstName}
          onExplore={() => session.navigate("explore")}
        />
      ) : null}

      {session.screen === "explore" ? (
        <ExploreScreen
          onNavigate={goToTab}
          onSelectVenue={session.selectVenue}
          onStartRsvp={session.startRsvp}
          onViewVenue={session.viewVenue}
          plan={session.plan}
          selectedVenueId={session.selectedVenueId}
        />
      ) : null}

      {session.screen === "list" ? (
        <ListScreen
          onNavigate={goToTab}
          onStartRsvp={session.startRsvp}
          onViewVenue={session.viewVenue}
        />
      ) : null}

      {session.screen === "profile" ? (
        <ProfileScreen
          checkedInVenueId={session.checkedInVenueId}
          onCancelPlan={session.cancelPlan}
          onChangePlan={session.startRsvp}
          onCheckin={session.startCheckin}
          onLogOut={session.resetPrototype}
          onNavigate={goToTab}
          onViewVenue={session.viewVenue}
          plan={session.plan}
          profile={session.profile}
        />
      ) : null}

      {session.screen === "venue_detail" ? (
        <VenueDetailScreen
          onBack={session.goBack}
          onStartCheckin={session.startCheckin}
          onStartRsvp={session.startRsvp}
          plan={session.plan}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "rsvp_arrival" ? (
        <RsvpArrivalScreen
          onBack={session.goBack}
          onNext={() => session.navigate("rsvp_group")}
          onSelect={session.setArrivalWindow}
          selected={session.arrivalWindow}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "rsvp_group" ? (
        <RsvpGroupScreen
          groupSize={session.groupSize}
          onBack={session.goBack}
          onChange={session.setGroupSize}
          onNext={() => session.navigate("rsvp_confirm")}
        />
      ) : null}

      {session.screen === "rsvp_confirm" ? (
        <RsvpConfirmScreen
          arrivalWindow={session.arrivalWindow}
          currentPlan={session.plan}
          groupSize={session.groupSize}
          onBack={session.goBack}
          onConfirm={session.confirmPlan}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "rsvp_success" && session.plan ? (
        <RsvpSuccessScreen
          onCheckin={() => session.startCheckin(selectedVenue.id)}
          onExplore={() => session.navigate("explore")}
          onViewVenue={() => session.viewVenue(selectedVenue.id)}
          plan={session.plan}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "checkin_intro" ? (
        <CheckinIntroScreen
          onBack={session.goBack}
          onScan={() => session.navigate("checkin_scan")}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "checkin_scan" ? (
        <CheckinScanScreen
          onBack={session.goBack}
          onCodeRead={() => session.navigate("checkin_location")}
        />
      ) : null}

      {session.screen === "checkin_location" ? (
        <CheckinLocationScreen
          onBack={session.goBack}
          onVerify={session.completeCheckin}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "checkin_success" ? (
        <CheckinSuccessScreen
          onExplore={() => session.navigate("explore")}
          onViewOffer={() => session.navigate("offer")}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "offer" ? (
        <OfferScreen
          onBack={session.goBack}
          onRedeem={() => session.navigate("redeem_confirm")}
          redeemed={session.offerRedeemed}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "redeem_confirm" ? (
        <RedeemConfirmScreen
          onBack={session.goBack}
          onConfirm={session.redeemOffer}
          venue={selectedVenue}
        />
      ) : null}

      {session.screen === "redeemed" ? (
        <RedeemedScreen
          onExplore={() => session.navigate("explore")}
          venue={selectedVenue}
        />
      ) : null}
    </PrototypeFrame>
  );
}

function WelcomeScreen({
  onGetStarted,
  onLogIn,
}: {
  onGetStarted: () => void;
  onLogIn: () => void;
}) {
  return (
    <div className="relative flex min-h-0 flex-1 flex-col overflow-hidden">
      <div
        className="absolute inset-x-0 bottom-36 h-64 opacity-75"
        aria-hidden="true"
      >
        <TorontoSkyline />
      </div>
      <div
        className="bg-accent-muted absolute top-24 -right-24 size-64 rounded-full blur-3xl"
        aria-hidden="true"
      />

      <main className="relative z-10 flex flex-1 flex-col px-6 pt-[8vh]">
        <OutlyLogo className="mx-auto" priority size="md" />
        <div className="mt-[8vh]">
          <span className="bg-accent-primary mb-5 block h-1 w-10 rounded-full" />
          <h1 className="text-text-primary max-w-sm text-[clamp(2.55rem,10vw,3.4rem)] leading-[0.92] font-semibold tracking-[-0.065em] text-balance">
            Say you met at a bar, not a dating app.
          </h1>
          <p className="text-text-secondary mt-5 max-w-xs text-[0.9375rem] leading-6">
            See where people are going tonight, pick a bar, and meet in real
            life.
          </p>
        </div>
      </main>

      <footer className="from-background-primary via-background-primary relative z-10 grid shrink-0 gap-2.5 bg-gradient-to-t to-transparent px-5 pt-16 pb-[max(1rem,env(safe-area-inset-bottom))]">
        <Button fullWidth onClick={onGetStarted} size="lg">
          Get Started
        </Button>
        <Button fullWidth onClick={onLogIn} size="lg" variant="secondary">
          Log In
        </Button>
        <p className="text-text-muted mt-2 text-center text-[0.65rem] leading-4">
          By continuing, you agree to our{" "}
          <span className="underline">Terms</span> and{" "}
          <span className="underline">Privacy Policy</span>.
        </p>
      </footer>
    </div>
  );
}

function AuthScreen({
  loading,
  onBack,
  onContinue,
}: {
  loading: "email" | "google" | null;
  onBack: () => void;
  onContinue: (provider: "email" | "google") => void;
}) {
  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <header className="px-4 pt-2">
        <button
          aria-label="Go back"
          className="text-text-secondary hover:bg-surface-primary hover:text-text-primary flex size-11 items-center justify-center rounded-full"
          onClick={onBack}
          type="button"
        >
          <Icon className="size-5" name="arrow-left" />
        </button>
      </header>
      <main className="flex flex-1 flex-col px-6 pt-[8vh]">
        <OutlyLogo size="sm" />
        <h1 className="text-text-primary mt-10 text-[2.5rem] leading-[0.98] font-semibold tracking-[-0.055em] text-balance">
          How do you want to continue?
        </h1>
        <p className="text-text-secondary mt-4 text-sm leading-6">
          Choose an option to start your private profile.
        </p>
        <div className="mt-10 grid gap-3">
          <Button
            fullWidth
            leadingIcon={<Icon className="size-5" name="mail" />}
            loading={loading === "email"}
            onClick={() => onContinue("email")}
            size="lg"
            variant="secondary"
          >
            Continue with Email
          </Button>
          <Button
            fullWidth
            leadingIcon={
              <span className="text-lg font-semibold" aria-hidden="true">
                G
              </span>
            }
            loading={loading === "google"}
            onClick={() => onContinue("google")}
            size="lg"
            variant="secondary"
          >
            Continue with Google
          </Button>
        </div>
      </main>
      <p className="text-text-muted px-8 pb-[max(1.5rem,env(safe-area-inset-bottom))] text-center text-xs leading-5">
        Prototype mode — no account will be created yet.
      </p>
    </div>
  );
}

function AgeSelector({
  age,
  onChange,
}: {
  age: number;
  onChange: (age: number) => void;
}) {
  return (
    <div className="rounded-sheet border-border-subtle bg-surface-primary mx-auto flex max-w-xs items-center justify-between border p-4">
      <button
        aria-label="Decrease age"
        className="rounded-control bg-surface-secondary text-text-primary flex size-14 items-center justify-center text-2xl disabled:opacity-30"
        disabled={age === 19}
        onClick={() => onChange(age - 1)}
        type="button"
      >
        −
      </button>
      <output aria-label={`Age ${age}`} className="text-center">
        <span className="text-text-primary block text-6xl font-semibold tracking-[-0.075em]">
          {age}
        </span>
        <span className="text-text-muted mt-1 block text-xs font-medium tracking-[0.14em] uppercase">
          years old
        </span>
      </output>
      <button
        aria-label="Increase age"
        className="rounded-control bg-surface-secondary text-text-primary flex size-14 items-center justify-center text-2xl disabled:opacity-30"
        disabled={age === 40}
        onClick={() => onChange(age + 1)}
        type="button"
      >
        +
      </button>
    </div>
  );
}

function CompletionScreen({
  firstName,
  onExplore,
}: {
  firstName: string;
  onExplore: () => void;
}) {
  return (
    <div className="relative flex min-h-0 flex-1 flex-col overflow-hidden px-6">
      <div
        className="city-grid absolute inset-0 opacity-20"
        aria-hidden="true"
      />
      <main className="relative z-10 flex flex-1 flex-col items-center justify-center text-center">
        <div className="relative">
          <span
            className="bg-accent-muted absolute inset-4 rounded-full blur-2xl"
            aria-hidden="true"
          />
          <OutlyLogo className="relative" priority size="lg" />
        </div>
        <span className="bg-accent-primary text-accent-foreground mt-6 flex size-12 items-center justify-center rounded-full">
          <Icon className="size-6" name="check" />
        </span>
        <h1 className="text-text-primary mt-6 text-4xl font-semibold tracking-[-0.055em]">
          You’re all set.
        </h1>
        <p className="text-text-secondary mt-3 text-sm">
          Welcome to Outly, {firstName}.
        </p>
      </main>
      <footer className="relative z-10 pb-[max(1rem,env(safe-area-inset-bottom))]">
        <Button
          fullWidth
          onClick={onExplore}
          size="lg"
          trailingIcon={<Icon className="size-4" name="arrow-right" />}
        >
          Explore Toronto
        </Button>
      </footer>
    </div>
  );
}
