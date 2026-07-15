import { expect, test } from "@playwright/test";

test("clicks through the complete Outly night-out journey", async ({
  page,
}) => {
  await page.goto("/");

  await expect(
    page.getByRole("heading", {
      name: "Say you met at a bar, not a dating app.",
    }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Get Started" }).click();
  await page.getByRole("button", { name: "Continue with Email" }).click();

  await page.getByLabel("First name").fill("Liam");
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "How old are you?" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await page.getByRole("button", { name: "Man", exact: true }).click();
  await page.getByRole("button", { name: "Next", exact: true }).click();
  await page.getByRole("button", { name: "Everyone" }).click();
  await page.getByRole("button", { name: "Next", exact: true }).click();

  await expect(
    page.getByRole("heading", { name: "You’re all set." }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Explore Toronto" }).click();
  await expect(
    page.getByRole("heading", { name: "Explore Toronto" }),
  ).toBeAttached();
  await expect(
    page.getByLabel("Toronto nightlife map placeholder"),
  ).toBeVisible();

  await page.getByRole("button", { name: "I’m Going" }).click();
  await expect(
    page.getByRole("heading", { name: "When are you getting there?" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "10:00–11:00 PM" }).click();
  await page.getByRole("button", { name: "Choose group size" }).click();
  await page.getByRole("button", { name: "3" }).click();
  await page.getByRole("button", { name: "Review plan" }).click();
  await page.getByRole("button", { name: "Confirm" }).click();

  await expect(
    page.getByRole("heading", { name: "You’re going to Track & Field." }),
  ).toBeVisible();
  await page.getByRole("button", { name: "I’m at the venue" }).click();
  await page.getByRole("button", { name: "Scan Outly code" }).click();
  await page.getByRole("button", { name: "Use demo Outly code" }).click();
  await page
    .getByRole("button", { name: "Allow approximate location" })
    .click();

  await expect(
    page.getByRole("heading", { name: "You’re checked in." }),
  ).toBeVisible();
  await page.getByRole("button", { name: "View Offer" }).click();
  await expect(
    page.getByRole("heading", { name: "Free cover before 10:00 PM" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Redeem offer" }).click();
  await page.getByRole("button", { name: "Confirm redemption" }).click();
  await expect(
    page.getByRole("heading", { name: "Offer used." }),
  ).toBeVisible();

  await page.getByRole("button", { name: "Back to Explore" }).click();
  await page.getByRole("button", { name: "List" }).click();
  await expect(page.getByRole("heading", { name: "Venue list" })).toBeVisible();
  await page.getByRole("button", { name: "Open filters" }).click();
  await expect(
    page.getByRole("dialog", { name: "Venue filters" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Has offer" }).click();
  await page.getByRole("button", { name: /Show \d+ venues/ }).click();

  await page.getByRole("button", { name: "Profile" }).click();
  await expect(page.getByRole("heading", { name: "Profile" })).toBeVisible();
  await expect(page.getByText("Track & Field").first()).toBeVisible();
  await expect(page.getByText("Verified tonight · 9:48 PM")).toBeVisible();
});
