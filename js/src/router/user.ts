import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { RouteLocationNormalized, RouteRecordRaw } from "vue-router";
import { i18n } from "@/utils/i18n";

const t = i18n.global.t;

export enum UserRouteName {
  REGISTER = "Register",
  REGISTER_PROFILE = "RegisterProfile",
  RESEND_CONFIRMATION = "ResendConfirmation",
  SEND_PASSWORD_RESET = "SendPasswordReset",
  PASSWORD_RESET = "PasswordReset",
  EMAIL_VALIDATE = "EMAIL_VALIDATE",
  VALIDATE = "Validate",
  LOGIN = "Login",
  OAUTH_AUTORIZE = "OAUTH_AUTORIZE",
}

export const userRoutes: RouteRecordRaw[] = [
  {
    path: "/register/user",
    name: UserRouteName.REGISTER,
    component: (): Promise<any> => import("@/views/User/RegisterView.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Register") as string },
    },
    beforeEnter: beforeRegisterGuard,
  },
  {
    path: "/register/profile/:email/:userAlreadyActivated?",
    name: UserRouteName.REGISTER_PROFILE,
    component: (): Promise<any> => import("@/views/Account/RegisterView.vue"),
    // We can only pass string values through params, therefore
    props: (route: RouteLocationNormalized): Record<string, unknown> => ({
      email: route.params.email,
      userAlreadyActivated: route.params.userAlreadyActivated === "true",
    }),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Register") as string },
    },
  },
  {
    path: "/resend-instructions",
    name: UserRouteName.RESEND_CONFIRMATION,
    component: (): Promise<any> =>
      import("@/views/User/ResendConfirmation.vue"),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: {
        message: (): string => t("Resent confirmation email") as string,
      },
    },
  },
  {
    path: "/password-reset/send",
    name: UserRouteName.SEND_PASSWORD_RESET,
    component: (): Promise<any> => import("@/views/User/SendPasswordReset.vue"),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: {
        message: (): string => t("Send password reset") as string,
      },
    },
  },
  {
    path: "/password-reset/:token",
    name: UserRouteName.PASSWORD_RESET,
    component: (): Promise<any> => import("@/views/User/PasswordReset.vue"),
    meta: {
      requiresAuth: false,
      announcer: { message: (): string => t("Password reset") as string },
    },
    props: true,
  },
  {
    path: "/validate/email/:token",
    name: UserRouteName.EMAIL_VALIDATE,
    component: (): Promise<any> => import("@/views/User/EmailValidate.vue"),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: { message: (): string => t("Email validate") as string },
    },
  },
  {
    path: "/validate/:token",
    name: UserRouteName.VALIDATE,
    component: (): Promise<any> => import("@/views/User/ValidateUser.vue"),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: {
        message: (): string => t("Validating account") as string,
      },
    },
  },
  {
    path: "/login",
    name: UserRouteName.LOGIN,
    component: (): Promise<any> => import("@/views/User/LoginView.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Login") as string },
    },
  },
  {
    path: "/oauth/autorize_approve",
    name: UserRouteName.OAUTH_AUTORIZE,
    component: (): Promise<any> => import("@/views/OAuth/AuthorizeView.vue"),
    meta: {
      requiredAuth: true,
      announcer: {
        message: (): string => t("Authorize application") as string,
      },
    },
  },
];
