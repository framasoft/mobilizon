import RegisterUser from '@/views/User/Register.vue';
import RegisterProfile from '@/views/Account/Register.vue';
import Login from '@/views/User/Login.vue';
import Validate from '@/views/User/Validate.vue';
import ResendConfirmation from '@/views/User/ResendConfirmation.vue';
import SendPasswordReset from '@/views/User/SendPasswordReset.vue';
import PasswordReset from '@/views/User/PasswordReset.vue';
import { beforeRegisterGuard } from '@/router/guards/register-guard';
import { RouteConfig } from 'vue-router';
import PasswordChange from '@/views/User/PasswordChange.vue';

export enum UserRouteName {
  REGISTER = 'Register',
  REGISTER_PROFILE = 'RegisterProfile',
  RESEND_CONFIRMATION = 'ResendConfirmation',
  SEND_PASSWORD_RESET = 'SendPasswordReset',
  PASSWORD_RESET = 'PasswordReset',
  VALIDATE = 'Validate',
  LOGIN = 'Login',
  PASSWORD_CHANGE = 'PasswordChange',
}

export const userRoutes: RouteConfig[] = [
  {
    path: '/register/user',
    name: UserRouteName.REGISTER,
    component: RegisterUser,
    props: true,
    meta: { requiredAuth: false },
    beforeEnter: beforeRegisterGuard,
  },
  {
    path: '/register/profile',
    name: UserRouteName.REGISTER_PROFILE,
    component: RegisterProfile,
    // We can only pass string values through params, therefore
    props: (route) => ({ email: route.params.email, userAlreadyActivated: route.params.userAlreadyActivated === 'true' }),
    meta: { requiredAuth: false },
  },
  {
    path: '/resend-instructions',
    name: UserRouteName.RESEND_CONFIRMATION,
    component: ResendConfirmation,
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: '/password-reset/send',
    name: UserRouteName.SEND_PASSWORD_RESET,
    component: SendPasswordReset,
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: '/password-reset/:token',
    name: UserRouteName.PASSWORD_RESET,
    component: PasswordReset,
    meta: { requiresAuth: false },
    props: true,
  },
  {
    path: '/validate/:token',
    name: UserRouteName.VALIDATE,
    component: Validate,
    props: true,
    meta: { requiresAuth: false },
  },
  {
    path: '/login',
    name: UserRouteName.LOGIN,
    component: Login,
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: '/my-account/password',
    name: UserRouteName.PASSWORD_CHANGE,
    component: PasswordChange,
    meta: { requiredAuth: true },
  },
];
