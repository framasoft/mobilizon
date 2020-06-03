import { beforeRegisterGuard } from "@/router/guards/register-guard";
import { RouteConfig } from "vue-router";

export enum UserRouteName {
  REGISTER = "Register",
  REGISTER_PROFILE = "RegisterProfile",
  RESEND_CONFIRMATION = "ResendConfirmation",
  SEND_PASSWORD_RESET = "SendPasswordReset",
  PASSWORD_RESET = "PasswordReset",
  VALIDATE = "Validate",
  LOGIN = "Login",
}

export const userRoutes: RouteConfig[] = [
  {
    path: "/register/user",
    name: UserRouteName.REGISTER,
    component: () => import("@/views/User/Register.vue"),
    props: true,
    meta: { requiredAuth: false },
    beforeEnter: beforeRegisterGuard,
  },
  {
    path: "/register/profile",
    name: UserRouteName.REGISTER_PROFILE,
    component: () => import("@/views/Account/Register.vue"),
    // We can only pass string values through params, therefore
    props: (route) => ({
      email: route.params.email,
      userAlreadyActivated: route.params.userAlreadyActivated === "true",
    }),
    meta: { requiredAuth: false },
  },
  {
    path: "/resend-instructions",
    name: UserRouteName.RESEND_CONFIRMATION,
    component: () => import("@/views/User/ResendConfirmation.vue"),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/password-reset/send",
    name: UserRouteName.SEND_PASSWORD_RESET,
    component: () => import("@/views/User/SendPasswordReset.vue"),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/password-reset/:token",
    name: UserRouteName.PASSWORD_RESET,
    component: () => import("@/views/User/PasswordReset.vue"),
    meta: { requiresAuth: false },
    props: true,
  },
  {
    path: "/validate/email/:token",
    name: UserRouteName.VALIDATE,
    component: () => import("@/views/User/EmailValidate.vue"),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/validate/:token",
    name: UserRouteName.VALIDATE,
    component: () => import("@/views/User/Validate.vue"),
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: "/login",
    name: UserRouteName.LOGIN,
    component: () => import("@/views/User/Login.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
];
