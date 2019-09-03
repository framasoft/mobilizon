<template>
  <div class="container">
    <section class="hero">
      <h1 class="title">
        <translate>Welcome back!</translate>
      </h1>
    </section>

    <b-message v-if="errorCode === LoginErrorCode.NEED_TO_LOGIN" title="Info" type="is-info">
      <translate>You need to login.</translate>
    </b-message>

    <section v-if="!currentUser.isLoggedIn">
      <div class="columns is-mobile is-centered">
        <div class="column is-half">
          <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
          <form @submit="loginAction">
            <b-field :label="$gettext('Email')">
              <b-input aria-required="true" required type="email" v-model="credentials.email"/>
            </b-field>

            <b-field :label="$gettext('Password')">
              <b-input
                aria-required="true"
                required
                type="password"
                password-reveal
                v-model="credentials.password"
              />
            </b-field>

            <div class="control has-text-centered">
              <button class="button is-primary is-large">
                <translate>Login</translate>
              </button>
            </div>
            <div class="control">
              <router-link
                class="button is-text"
                :to="{ name: 'SendPasswordReset', params: { email: credentials.email }}"
              >
                <translate>Forgot your password ?</translate>
              </router-link>
            </div>
            <div class="control" v-if="config && config.registrationsOpen">
              <router-link
                class="button is-text"
                :to="{ name: 'Register', params: { default_email: credentials.email, default_password: credentials.password }}"
              >
                <translate>Register</translate>
              </router-link>
            </div>
          </form>
        </div>
      </div>
    </section>

    <b-message v-else title="Error" type="is-error">
      <translate>You are already logged-in.</translate>
    </b-message>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { LOGIN } from '@/graphql/auth';
import { validateEmailField, validateRequiredField } from '@/utils/validators';
import { saveUserData } from '@/utils/auth';
import { ILogin } from '@/types/login.model';
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from '@/graphql/user';
import { onLogin } from '@/vue-apollo';
import { RouteName } from '@/router';
import { LoginErrorCode } from '@/types/login-error-code.model';
import { ICurrentUser } from '@/types/current-user.model';
import { CONFIG } from '@/graphql/config';
import { IConfig } from '@/types/config.model';

@Component({
  apollo: {
    config: {
      query: CONFIG,
    },
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
  },
})
export default class Login extends Vue {
  @Prop({ type: String, required: false, default: '' }) email!: string;
  @Prop({ type: String, required: false, default: '' }) password!: string;

  LoginErrorCode = LoginErrorCode;

  errorCode: LoginErrorCode | null = null;
  config!: IConfig;
  currentUser!: ICurrentUser;

  credentials = {
    email: '',
    password: '',
  };
  validationSent = false;

  errors: string[] = [];
  rules = {
    required: validateRequiredField,
    email: validateEmailField,
  };

  private redirect: string | null = null;

  mounted() {
    this.credentials.email = this.email;
    this.credentials.password = this.password;

    const query = this.$route.query;
    this.errorCode = query['code'] as LoginErrorCode;
    this.redirect = query['redirect'] as string;
  }

  async loginAction(e: Event) {
    e.preventDefault();

    this.errors = [];

    try {
      const { data } = await this.$apollo.mutate<{ login: ILogin }>({
        mutation: LOGIN,
        variables: {
          email: this.credentials.email,
          password: this.credentials.password,
        },
      });
      if (data == null) {
        throw new Error('Data is undefined');
      }

      saveUserData(data.login);

      await this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: data.login.user.id,
          email: this.credentials.email,
          isLoggedIn: true,
        },
      });

      onLogin(this.$apollo);

      if (this.redirect) {
        await this.$router.push(this.redirect);
      } else {
        await this.$router.push({ name: RouteName.HOME });
      }
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }) => {
        this.errors.push(message);
      });
    }
  }
}
</script>
