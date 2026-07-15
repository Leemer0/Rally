import { expect, test } from "@playwright/test";

test("renders the Rally foundation across responsive shells", async ({
  page,
}, testInfo) => {
  await page.goto("/");

  await expect(
    page.getByRole("heading", { name: "Tonight, made legible." }),
  ).toBeVisible();
  await expect(page.getByText("Theme online")).toBeVisible();
  await expect(page.getByRole("region", { name: "Lavelle" })).toBeVisible();

  const conversationChip = page.getByRole("button", {
    name: "Good conversation",
  });
  const danceFloorChip = page.getByRole("button", { name: "Dance floor" });
  await expect(conversationChip).toHaveAttribute("aria-pressed", "true");
  await danceFloorChip.click();
  await expect(danceFloorChip).toHaveAttribute("aria-pressed", "true");
  await expect(conversationChip).toHaveAttribute("aria-pressed", "false");

  if (testInfo.project.name === "mobile-chrome") {
    await expect(
      page.getByRole("navigation", { name: "Primary navigation" }).last(),
    ).toBeVisible();
    await expect(page.locator("aside")).toBeHidden();
  } else {
    await expect(page.locator("aside")).toBeVisible();
    await expect(
      page.getByRole("navigation", { name: "Primary navigation" }).last(),
    ).toBeVisible();
  }
});
