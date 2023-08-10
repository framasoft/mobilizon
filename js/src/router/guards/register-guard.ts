import { IConfig } from "@/types/config.model";
import { ErrorCode } from "@/types/enums";
import { provideApolloClient, useQuery } from "@vue/apollo-composable";
import { NavigationGuard } from "vue-router";
import { CONFIG } from "../../graphql/config";
import { apolloClient } from "../../vue-apollo";
import { ErrorRouteName } from "../error";

export const beforeRegisterGuard: NavigationGuard = async (to, from, next) => {
  const { onResult, onError } = provideApolloClient(apolloClient)(() =>
    useQuery<{ config: IConfig }>(CONFIG)
  );

  onResult(({ data }) => {
    if (!data) return next();
    const { config } = data;

    if (!config.registrationsOpen && !config.registrationsAllowlist) {
      return next({
        name: ErrorRouteName.ERROR,
        query: { code: ErrorCode.REGISTRATION_CLOSED },
      });
    }

    return next();
  });

  onError((err) => {
    console.error(err);
    return next();
  });
  return next();
};
