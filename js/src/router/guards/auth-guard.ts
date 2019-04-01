import { NavigationGuard } from 'vue-router';
import { UserRouteName } from '@/router/user';
import { LoginErrorCode } from '@/types/login-error-code.model';
import { AUTH_TOKEN } from '@/constants';

export const authGuardIfNeeded: NavigationGuard = async function (to, from, next) {
  if (to.meta.requiredAuth !== true) return next();

  // We can't use "currentUser" from apollo here because we may not have loaded the user from the local storage yet
  if (!localStorage.getItem(AUTH_TOKEN)) {
    return next({
      name: UserRouteName.LOGIN,
      query: {
        code: LoginErrorCode.NEED_TO_LOGIN,
        redirect: to.fullPath,
      },
    });
  }

  return next();
};
