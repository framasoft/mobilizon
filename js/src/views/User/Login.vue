<template>
  <section class="section container" v-if="!currentUser.isLoggedIn">
    <div class="columns is-mobile is-centered">
      <div class="column is-half-desktop">
        <h1 class="title">{{ $t("Welcome back!") }}</h1>
        <b-message
          v-if="errorCode === LoginErrorCode.NEED_TO_LOGIN"
          title="Info"
          type="is-info"
          :aria-close-label="$t('Close')"
          >{{ $t("You need to login.") }}</b-message
        >
        <b-message
          v-else-if="errorCode === LoginError.LOGIN_PROVIDER_ERROR"
          type="is-danger"
          :aria-close-label="$t('Close')"
          >{{
            $t("Error while login with {provider}. Retry or login another way.", {
              provider: $route.query.provider,
            })
          }}</b-message
        >
        <b-message
          v-else-if="errorCode === LoginError.LOGIN_PROVIDER_NOT_FOUND"
          type="is-danger"
          :aria-close-label="$t('Close')"
          >{{
            $t("Error while login with {provider}. This login provider doesn't exist.", {
              provider: $route.query.provider,
            })
          }}</b-message
        >
        <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">
          <span v-if="error === LoginError.USER_NOT_CONFIRMED">
            <span>
              {{
                $t(
                  "The user account you're trying to login as has not been confirmed yet. Check your email inbox and eventually your spam folder."
                )
              }}
            </span>
            <i18n path="You may also ask to {resend_confirmation_email}.">
              <router-link
                slot="resend_confirmation_email"
                :to="{ name: RouteName.RESEND_CONFIRMATION }"
                >{{ $t("resend confirmation email") }}</router-link
              >
            </i18n>
          </span>
          <span v-if="error === LoginError.USER_EMAIL_PASSWORD_INVALID">{{
            $t("Impossible to login, your email or password seems incorrect.")
          }}</span>
          <!-- TODO: Shouldn't we hide this information? -->
          <span v-if="error === LoginError.USER_DOES_NOT_EXIST">{{
            $t("No user account with this email was found. Maybe you made a typo?")
          }}</span>
        </b-message>
        <form @submit="loginAction">
          <b-field :label="$t('Email')" label-for="email">
            <b-input
              aria-required="true"
              required
              id="email"
              type="email"
              v-model="credentials.email"
            />
          </b-field>

          <b-field :label="$t('Password')" label-for="password">
            <b-input
              aria-required="true"
              id="password"
              required
              type="password"
              password-reveal
              v-model="credentials.password"
            />
          </b-field>

          <p class="control has-text-centered">
            <button class="button is-primary is-large">{{ $t("Login") }}</button>
          </p>

          <div class="control" v-if="config && config.auth.oauthProviders.length > 0">
            <auth-providers :oauthProviders="config.auth.oauthProviders" />
          </div>

          <p class="control">
            <router-link
              class="button is-text"
              :to="{ name: RouteName.SEND_PASSWORD_RESET, params: { email: credentials.email } }"
              >{{ $t("Forgot your password ?") }}</router-link
            >
          </p>
          <router-link
            class="button is-text"
            :to="{ name: RouteName.RESEND_CONFIRMATION, params: { email: credentials.email } }"
            >{{ $t("Didn't receive the instructions ?") }}</router-link
          >
          <p class="control" v-if="config && config.registrationsOpen">
            <router-link
              class="button is-text"
              :to="{
                name: RouteName.REGISTER,
                params: {
                  default_email: credentials.email,
                  default_password: credentials.password,
                },
              }"
              >{{ $t("Register") }}</router-link
            >
          </p>
        </form>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { LOGIN } from "../../graphql/auth";
import { validateEmailField, validateRequiredField } from "../../utils/validators";
import { initializeCurrentActor, NoIdentitiesException, saveUserData } from "../../utils/auth";
import { ILogin } from "../../types/login.model";
import { CURRENT_USER_CLIENT, UPDATE_CURRENT_USER_CLIENT } from "../../graphql/user";
import RouteName from "../../router/name";
import { LoginErrorCode, LoginError } from "../../types/login-error-code.model";
import { ICurrentUser } from "../../types/current-user.model";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import AuthProviders from "../../components/User/AuthProviders.vue";

@Component({
  apollo: {
    config: {
      query: CONFIG,
    },
    currentUser: {
      query: CURRENT_USER_CLIENT,
    },
  },
  components: {
    AuthProviders,
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t("Login on Mobilizon!") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Login extends Vue {
  @Prop({ type: String, required: false, default: "" }) email!: string;

  @Prop({ type: String, required: false, default: "" }) password!: string;

  LoginErrorCode = LoginErrorCode;

  LoginError = LoginError;

  errorCode: LoginErrorCode | null = null;

  config!: IConfig;

  currentUser!: ICurrentUser;

  RouteName = RouteName;

  credentials = {
    email: "",
    password: "",
  };

  errors: string[] = [];

  rules = {
    required: validateRequiredField,
    email: validateEmailField,
  };

  private redirect: string | null = null;

  mounted() {
    this.credentials.email = this.email;
    this.credentials.password = this.password;

    const { query } = this.$route;
    this.errorCode = query.code as LoginErrorCode;
    this.redirect = query.redirect as string;
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
        throw new Error("Data is undefined");
      }

      saveUserData(data.login);

      await this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: data.login.user.id,
          email: this.credentials.email,
          isLoggedIn: true,
          role: data.login.user.role,
        },
      });
      try {
        await initializeCurrentActor(this.$apollo.provider.defaultClient);
      } catch (err) {
        if (err instanceof NoIdentitiesException) {
          return this.$router.push({
            name: RouteName.REGISTER_PROFILE,
            params: {
              email: this.currentUser.email,
              userAlreadyActivated: "true",
            },
          });
        }
      }

      if (this.redirect) {
        return this.$router.push(this.redirect);
      }
      window.localStorage.setItem("welcome-back", "yes");
      return this.$router.push({ name: RouteName.HOME });
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }: { message: string }) => {
        this.errors.push(message);
      });
      return undefined;
    }
  }
}
</script>

<style lang="scss" scoped>
.container .columns {
  margin: 1rem auto 3rem;
}
</style>
