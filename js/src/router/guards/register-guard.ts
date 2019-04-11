import { apolloProvider } from '@/vue-apollo';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';
import { NavigationGuard } from 'vue-router';
import { ErrorRouteName } from '@/router/error';
import { ErrorCode } from '@/types/error-code.model';

export const beforeRegisterGuard: NavigationGuard = async function (to, from, next) {
  const { data } = await apolloProvider.defaultClient.query({
    query: CONFIG,
  });

  const config: IConfig = data.config;

  if (!config.registrationsOpen) {
    return next({
      name: ErrorRouteName.ERROR,
      query: { code: ErrorCode.REGISTRATION_CLOSED },
    });
  }

  return next();
};
