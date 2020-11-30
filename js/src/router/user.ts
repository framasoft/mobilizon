import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { Route, RouteConfig } from "vue-router";
import { EsModuleComponent } from "vue/types/options";

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
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "RegisterUser" */ "@/views/User/Register.vue"
      ),
    props: true,
    meta: { requiredAuth: false },
    beforeEnter: beforeRegisterGuard,
  },
  {
    path: "/register/profile",
    name: UserRouteName.REGISTER_PROFILE,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "RegisterProfile" */ "@/views/Account/Register.vue"
      ),
    // We can only pass string values through params, therefore
    props: (route: Route): Record<string, unknown> => ({
      email: route.params.email,
      userAlreadyActivated: route.params.userAlreadyActivated === "true",
    }),
    meta: { requiredAuth: false },
  },
  {
    path: "/resend-instructions",
    name: UserRouteName.RESEND_CONFIRMATION,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "ResendConfirmation" */ "@/views/User/ResendConfirmation.vue"
      ),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/password-reset/send",
    name: UserRouteName.SEND_PASSWORD_RESET,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "SendPasswordReset" */ "@/views/User/SendPasswordReset.vue"
      ),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/password-reset/:token",
    name: UserRouteName.PASSWORD_RESET,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "PasswordReset" */ "@/views/User/PasswordReset.vue"
      ),
    meta: { requiresAuth: false },
    props: true,
  },
  {
    path: "/validate/email/:token",
    name: UserRouteName.EMAIL_VALIDATE,
    component: (): Promise<EsModuleComponent> =>
      import(
        /* webpackChunkName: "EmailValidate" */ "@/views/User/EmailValidate.vue"
      ),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/validate/:token",
    name: UserRouteName.VALIDATE,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "Validate" */ "@/views/User/Validate.vue"),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/login",
    name: UserRouteName.LOGIN,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "Login" */ "@/views/User/Login.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
];
