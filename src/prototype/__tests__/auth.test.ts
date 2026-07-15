import { prototypeAuthGateway } from "@/prototype/auth";

describe("prototype authentication gateway", () => {
  it.each(["email", "google"] as const)(
    "isolates the %s bypass behind one gateway",
    async (provider) => {
      await expect(
        prototypeAuthGateway.continueWith(provider),
      ).resolves.toMatchObject({
        provider,
        userId: expect.any(String),
      });
    },
  );
});
