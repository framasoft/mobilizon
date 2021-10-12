import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { Route, RouteConfig } from "vue-router";
import { ImportedComponent } from "vue/types/options";
import { i18n } from "@/utils/i18n";

export enum UserRouteName {
  REGISTER = "Register",
  REGISTER_PROFILE = "RegisterProfile",
  RESEND_CONFIRMATION = "ResendConfirmation",
  SEND_PASSWORD_RESET = "SendPasswordReset",
  PASSWORD_RESET = "PasswordReset",
  EMAIL_VALIDATE = "EMAIL_VALIDATE",
  VALIDATE = "Validate",
  LOGIN = "Login",
}

export const userRoutes: RouteConfig[] = [
  {
    path: "/register/user",
    name: UserRouteName.REGISTER,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "RegisterUser" */ "@/views/User/Register.vue"
      ),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Register") as string },
    },
    beforeEnter: beforeRegisterGuard,
  },
  {
    path: "/register/profile",
    name: UserRouteName.REGISTER_PROFILE,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "RegisterProfile" */ "@/views/Account/Register.vue"
      ),
    // We can only pass string values through params, therefore
    props: (route: Route): Record<string, unknown> => ({
      email: route.params.email,
      userAlreadyActivated: route.params.userAlreadyActivated === "true",
    }),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Register") as string },
    },
  },
  {
    path: "/resend-instructions",
    name: UserRouteName.RESEND_CONFIRMATION,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "ResendConfirmation" */ "@/views/User/ResendConfirmation.vue"
      ),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: {
        message: (): string => i18n.t("Resent confirmation email") as string,
      },
    },
  },
  {
    path: "/password-reset/send",
    name: UserRouteName.SEND_PASSWORD_RESET,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "SendPasswordReset" */ "@/views/User/SendPasswordReset.vue"
      ),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: {
        message: (): string => i18n.t("Send password reset") as string,
      },
    },
  },
  {
    path: "/password-reset/:token",
    name: UserRouteName.PASSWORD_RESET,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "PasswordReset" */ "@/views/User/PasswordReset.vue"
      ),
    meta: {
      requiresAuth: false,
      announcer: { message: (): string => i18n.t("Password reset") as string },
    },
    props: true,
  },
  {
    path: "/validate/email/:token",
    name: UserRouteName.EMAIL_VALIDATE,
    component: (): Promise<ImportedComponent> =>
      import(
        /* webpackChunkName: "EmailValidate" */ "@/views/User/EmailValidate.vue"
      ),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: { message: (): string => i18n.t("Email validate") as string },
    },
  },
  {
    path: "/validate/:token",
    name: UserRouteName.VALIDATE,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Validate" */ "@/views/User/Validate.vue"),
    props: true,
    meta: {
      requiresAuth: false,
      announcer: {
        message: (): string => i18n.t("Validating account") as string,
      },
    },
  },
  {
    path: "/login",
    name: UserRouteName.LOGIN,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Login" */ "@/views/User/Login.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Login") as string },
    },
  },
];
