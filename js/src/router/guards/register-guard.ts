import { ErrorCode } from "@/types/enums";
import { NavigationGuard } from "vue-router";
import { CONFIG } from "../../graphql/config";
import apolloProvider from "../../vue-apollo";

// eslint-disable-next-line import/prefer-default-export
export const beforeRegisterGuard: NavigationGuard = async (to, from, next) => {
  const { data } = await apolloProvider.defaultClient.query({
    query: CONFIG,
  });

  const { config } = data;

  if (!config.registrationsOpen && !config.registrationsAllowlist) {
    return next({
      name: "Error",
      query: { code: ErrorCode.REGISTRATION_CLOSED },
    });
  }

  return next();
};
