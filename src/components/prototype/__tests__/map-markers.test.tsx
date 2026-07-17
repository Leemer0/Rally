import { existsSync } from "node:fs";
import path from "node:path";

import { render, screen, within } from "@testing-library/react";

import { ExploreScreen } from "@/components/prototype/ExploreScreen";

describe("ExploreScreen map markers", () => {
  it("uses venue-specific artwork without rendering attendance bubbles", () => {
    render(
      <ExploreScreen
        onNavigate={() => undefined}
        onSelectVenue={() => undefined}
        onStartRsvp={() => undefined}
        onViewVenue={() => undefined}
        plan={null}
        selectedVenueId="track-field"
      />,
    );

    const markers = [
      ["Track & Field", 46, "track-field.png"],
      ["Lavelle", 38, "lavelle.png"],
      ["Baro", 24, "baro.png"],
      ["Paris Texas", 17, "paris-texas.png"],
    ] as const;

    for (const [name, attendance, artwork] of markers) {
      const marker = screen.getByRole("button", {
        name: `${name}, ${attendance} going`,
      });
      const image = marker.querySelector("img");

      expect(image?.getAttribute("src")).toContain(artwork);
      expect(
        existsSync(path.join(process.cwd(), "public/venue-markers", artwork)),
      ).toBe(true);
      expect(
        within(marker).queryByText(String(attendance)),
      ).not.toBeInTheDocument();
    }
  });
});
