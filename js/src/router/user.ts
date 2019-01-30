import RegisterUser from '@/views/User/Register.vue';
import RegisterProfile from '@/views/Account/Register.vue';
import Login from '@/views/User/Login.vue';
import Validate from '@/views/User/Validate.vue';
import ResendConfirmation from '@/views/User/ResendConfirmation.vue';
import SendPasswordReset from '@/views/User/SendPasswordReset.vue';
import PasswordReset from '@/views/User/PasswordReset.vue';

export default [
    {
        path: '/register/user',
        name: 'Register',
        component: RegisterUser,
        props: true,
        meta: { requiredAuth: false },
    },
    {
        path: '/register/profile',
        name: 'RegisterProfile',
        component: RegisterProfile,
        props: true,
        meta: { requiredAuth: false },
    },
    {
        path: '/resend-instructions',
        name: 'ResendConfirmation',
        component: ResendConfirmation,
        props: true,
        meta: { requiresAuth: false },
    },
    {
        path: '/password-reset/send',
        name: 'SendPasswordReset',
        component: SendPasswordReset,
        props: true,
        meta: { requiresAuth: false },
    },
    {
        path: '/password-reset/:token',
        name: 'PasswordReset',
        component: PasswordReset,
        meta: { requiresAuth: false },
        props: true,
    },
    {
        path: '/validate/:token',
        name: 'Validate',
        component: Validate,
        // We can only pass string values through params, therefore
        props: (route) => ({ email: route.params.email, userAlreadyActivated: route.params.userAlreadyActivated === 'true'}),
        meta: { requiresAuth: false },
    },
    {
        path: '/login',
        name: 'Login',
        component: Login,
        props: true,
        meta: { requiredAuth: false },
    },
];