import type { AuthProvider } from "@/prototype/types";

export type PrototypeAuthSession = {
  userId: string;
  provider: AuthProvider;
};

export interface AuthGateway {
  continueWith(provider: AuthProvider): Promise<PrototypeAuthSession>;
}

/**
 * Development-only authentication boundary.
 *
 * TODO(auth): Replace this gateway with Supabase signInWithOtp/signInWithOAuth
 * and map the returned session to the same shape. Keeping the bypass here
 * prevents prototype-only behavior from leaking into onboarding screens.
 */
export const prototypeAuthGateway: AuthGateway = {
  async continueWith(provider) {
    return {
      userId: "00000000-0000-4000-8000-000000000001",
      provider,
    };
  },
};
