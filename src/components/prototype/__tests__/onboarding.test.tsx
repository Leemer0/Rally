import { fireEvent, render, screen } from "@testing-library/react";

import { OutlyPrototype } from "@/components/prototype/OutlyPrototype";

async function reachNameStep(provider: "Email" | "Google" = "Email") {
  fireEvent.click(screen.getByRole("button", { name: "Get Started" }));
  fireEvent.click(
    screen.getByRole("button", { name: `Continue with ${provider}` }),
  );
  await screen.findByRole("heading", { name: "What’s your name?" });
}

describe("Outly prototype onboarding", () => {
  it("follows the required five-step flow and routes to Explore Toronto", async () => {
    render(<OutlyPrototype />);

    expect(
      screen.getByRole("heading", {
        name: "Say you met at a bar, not a dating app.",
      }),
    ).toBeInTheDocument();
    await reachNameStep();

    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(screen.getByRole("alert")).toHaveTextContent(
      "Please enter your first name",
    );

    fireEvent.change(screen.getByLabelText("First name"), {
      target: { value: "  Liam  " },
    });
    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(
      screen.getByRole("heading", { name: "How old are you?" }),
    ).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Next" }));
    expect(
      screen.getByRole("heading", { name: "How do you identify?" }),
    ).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Woman" }));
    fireEvent.click(screen.getByRole("button", { name: "Next" }));

    expect(
      screen.getByRole("heading", {
        name: "Who are you interested in meeting?",
      }),
    ).toBeInTheDocument();
    fireEvent.click(screen.getByRole("button", { name: "Everyone" }));
    fireEvent.click(screen.getByRole("button", { name: "Next" }));

    expect(
      screen.getByRole("heading", { name: "You’re all set." }),
    ).toBeInTheDocument();
    expect(
      screen.queryByText(
        /preferred age|neighbourhood|venue vibe|open to meet/i,
      ),
    ).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Explore Toronto" }));
    expect(
      screen.getByRole("heading", { name: "Explore Toronto" }),
    ).toBeInTheDocument();
  });

  it("allows the Google prototype option to continue", async () => {
    render(<OutlyPrototype />);
    await reachNameStep("Google");
    expect(screen.getByLabelText("First name")).toBeInTheDocument();
  });

  it("keeps the age selector within 19 and 40", async () => {
    render(<OutlyPrototype />);
    await reachNameStep();
    fireEvent.change(screen.getByLabelText("First name"), {
      target: { value: "Rae" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Next" }));

    const decrease = screen.getByRole("button", { name: "Decrease age" });
    for (let index = 0; index < 8; index += 1) fireEvent.click(decrease);
    expect(screen.getByLabelText("Age 19")).toBeInTheDocument();
    expect(decrease).toBeDisabled();

    const increase = screen.getByRole("button", { name: "Increase age" });
    for (let index = 0; index < 24; index += 1) fireEvent.click(increase);
    expect(screen.getByLabelText("Age 40")).toBeInTheDocument();
    expect(increase).toBeDisabled();
  });
});
