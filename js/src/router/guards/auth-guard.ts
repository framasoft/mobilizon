import { NavigationGuard } from "vue-router";
import { UserRouteName } from "@/router/user";
import { AUTH_ACCESS_TOKEN } from "@/constants";
import { LoginErrorCode } from "@/types/enums";

export const authGuardIfNeeded: NavigationGuard = async (to, from, next) => {
  if (to.meta.requiredAuth !== true) return next();

  // We can't use "currentUser" from apollo here
  // because we may not have loaded the user from the local storage yet
  if (!localStorage.getItem(AUTH_ACCESS_TOKEN)) {
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
