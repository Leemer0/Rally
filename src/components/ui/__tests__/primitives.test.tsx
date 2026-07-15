import { fireEvent, render, screen } from "@testing-library/react";

import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { Input } from "@/components/ui/Input";
import { Navigation } from "@/components/ui/Navigation";
import { ProgressBar } from "@/components/ui/ProgressBar";
import { Sheet } from "@/components/ui/Sheet";

describe("Outly UI primitives", () => {
  it("disables a loading button and exposes its busy state", () => {
    render(<Button loading>Save plan</Button>);

    const button = screen.getByRole("button", { name: "Save plan" });
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute("aria-busy", "true");
  });

  it("connects input labels, hints, and errors", () => {
    const { rerender } = render(
      <Input
        hint="Only you can see this."
        label="Display name"
        placeholder="Enter your name"
      />,
    );

    const input = screen.getByLabelText("Display name");
    expect(input).toHaveAccessibleDescription("Only you can see this.");

    rerender(<Input error="Please enter your name" label="Display name" />);
    expect(screen.getByLabelText("Display name")).toHaveAccessibleDescription(
      "Please enter your name",
    );
    expect(screen.getByRole("alert")).toHaveTextContent(
      "Please enter your name",
    );
  });

  it("exposes chip selection without relying on colour", () => {
    const onClick = vi.fn();
    render(
      <Chip onClick={onClick} selected>
        Good conversation
      </Chip>,
    );

    const chip = screen.getByRole("button", { name: "Good conversation" });
    expect(chip).toHaveAttribute("aria-pressed", "true");
    fireEvent.click(chip);
    expect(onClick).toHaveBeenCalledOnce();
  });

  it("clamps progress values and preserves the original maximum", () => {
    render(<ProgressBar label="Onboarding progress" max={9} value={12} />);

    const progress = screen.getByRole("progressbar", {
      name: "Onboarding progress",
    });
    expect(progress).toHaveAttribute("aria-valuemax", "9");
    expect(progress).toHaveAttribute("aria-valuenow", "9");
  });

  it("marks the active navigation destination", () => {
    render(
      <Navigation
        activeHref="/"
        items={[
          { href: "/", icon: "compass", label: "Explore" },
          { href: "/venues", icon: "list", label: "List" },
          { href: "/profile", icon: "profile", label: "Profile" },
        ]}
      />,
    );

    expect(screen.getByRole("link", { name: "Explore" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(
      screen.getByRole("navigation", { name: "Primary navigation" }),
    ).toBeInTheDocument();
  });

  it("gives sheets a named landmark", () => {
    render(
      <Sheet
        footer={<Button>Continue</Button>}
        title="Choose an arrival window"
      >
        <p>9:00–9:30 PM</p>
      </Sheet>,
    );

    expect(
      screen.getByRole("region", { name: "Choose an arrival window" }),
    ).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Continue" }),
    ).toBeInTheDocument();
  });
});
