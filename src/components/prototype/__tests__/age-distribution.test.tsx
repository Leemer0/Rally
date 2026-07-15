import { render, screen } from "@testing-library/react";

import { AgeDistributionSparkline } from "@/components/prototype/AgeDistributionSparkline";

describe("AgeDistributionSparkline", () => {
  it("provides an accessible summary for available data", () => {
    render(
      <AgeDistributionSparkline
        maxAge={40}
        minAge={19}
        peakAge={27}
        points={[
          { age: 19, intensity: 0.1 },
          { age: 27, intensity: 1 },
          { age: 40, intensity: 0.05 },
        ]}
        status="available"
      />,
    );

    expect(
      screen.getByRole("img", {
        name: "Age distribution from 19 to 40, peaking around age 27.",
      }),
    ).toBeInTheDocument();
  });

  it("renders the privacy-safe limited-data state", () => {
    render(
      <AgeDistributionSparkline
        maxAge={40}
        minAge={19}
        peakAge={null}
        points={[]}
        status="limited_data"
      />,
    );

    expect(
      screen.getByRole("img", {
        name: "Age distribution is unavailable because there is not enough attendance data.",
      }),
    ).toBeInTheDocument();
    expect(screen.getByText("More attendance data needed")).toBeInTheDocument();
  });
});
