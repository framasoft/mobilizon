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
            $t(
              "Error while login with {provider}. Retry or login another way.",
              {
                provider:
                  SELECTED_PROVIDERS[$route.query.provider] ||
                  "unknown provider",
              }
            )
          }}</b-message
        >
        <b-message
          v-else-if="errorCode === LoginError.LOGIN_PROVIDER_NOT_FOUND"
          type="is-danger"
          :aria-close-label="$t('Close')"
          >{{
            $t(
              "Error while login with {provider}. This login provider doesn't exist.",
              {
                provider:
                  SELECTED_PROVIDERS[$route.query.provider] ||
                  "unknown provider",
              }
            )
          }}</b-message
        >
        <b-message
          :title="$t('Error')"
          type="is-danger"
          v-for="error in errors"
          :key="error"
        >
          {{ error }}
        </b-message>
        <form @submit="loginAction">
          <b-field
            :label="$t('Email')"
            label-for="email"
            :message="caseWarningText"
            :type="caseWarningType"
          >
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

          <p class="control has-text-centered" v-if="!submitted">
            <button type="submit" class="button is-primary is-large">
              {{ $t("Login") }}
            </button>
          </p>
          <b-loading :is-full-page="false" v-model="submitted" />

          <div
            class="control"
            v-if="config && config.auth.oauthProviders.length > 0"
          >
            <auth-providers :oauthProviders="config.auth.oauthProviders" />
          </div>

          <p class="control">
            <router-link
              class="button is-text"
              :to="{
                name: RouteName.SEND_PASSWORD_RESET,
                params: { email: credentials.email },
              }"
              >{{ $t("Forgot your password ?") }}</router-link
            >
          </p>
          <router-link
            class="button is-text"
            :to="{
              name: RouteName.RESEND_CONFIRMATION,
              params: { email: credentials.email },
            }"
            >{{ $t("Didn't receive the instructions?") }}</router-link
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
              >{{ $t("Create an account") }}</router-link
            >
          </p>
        </form>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { Route } from "vue-router";
import { ICurrentUser } from "@/types/current-user.model";
import { LoginError, LoginErrorCode } from "@/types/enums";
import { LOGIN } from "../../graphql/auth";
import {
  validateEmailField,
  validateRequiredField,
} from "../../utils/validators";
import {
  initializeCurrentActor,
  NoIdentitiesException,
  saveUserData,
  SELECTED_PROVIDERS,
} from "../../utils/auth";
import { ILogin } from "../../types/login.model";
import {
  CURRENT_USER_CLIENT,
  UPDATE_CURRENT_USER_CLIENT,
} from "../../graphql/user";
import RouteName from "../../router/name";
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
      title: this.$t("Login on Mobilizon!") as string,
      titleTemplate: "%s | Mobilizon",
      meta: [{ name: "robots", content: "noindex" }],
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

  redirect: string | undefined = "";

  errors: string[] = [];

  rules = {
    required: validateRequiredField,
    email: validateEmailField,
  };

  SELECTED_PROVIDERS = SELECTED_PROVIDERS;

  submitted = false;

  mounted(): void {
    this.credentials.email = this.email;
    this.credentials.password = this.password;

    const { query } = this.$route;
    this.errorCode = query.code as LoginErrorCode;
    this.redirect = query.redirect as string | undefined;

    // Already-logged-in and accessing /login
    if (this.currentUser.isLoggedIn) {
      this.$router.push("/");
    }
  }

  async loginAction(e: Event): Promise<Route | void> {
    e.preventDefault();
    if (this.submitted) {
      return;
    }

    this.errors = [];

    try {
      this.submitted = true;
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
      await this.setupClientUserAndActors(data.login);

      if (this.redirect) {
        this.$router.push(this.redirect as string);
        return;
      }
      if (window.localStorage) {
        window.localStorage.setItem("welcome-back", "yes");
      }
      this.$router.replace({ name: RouteName.HOME });
      return;
    } catch (err: any) {
      this.submitted = false;
      if (err.graphQLErrors) {
        err.graphQLErrors.forEach(({ message }: { message: string }) => {
          this.errors.push(message);
        });
      } else if (err.networkError) {
        this.errors.push(err.networkError.message);
      }
    }
  }

  private async setupClientUserAndActors(login: ILogin): Promise<void> {
    await this.$apollo.mutate({
      mutation: UPDATE_CURRENT_USER_CLIENT,
      variables: {
        id: login.user.id,
        email: this.credentials.email,
        isLoggedIn: true,
        role: login.user.role,
      },
    });
    try {
      await initializeCurrentActor(this.$apollo.provider.defaultClient);
    } catch (err: any) {
      if (err instanceof NoIdentitiesException) {
        await this.$router.push({
          name: RouteName.REGISTER_PROFILE,
          params: {
            email: this.currentUser.email,
            userAlreadyActivated: "true",
          },
        });
      }
    }
  }

  get hasCaseWarning(): boolean {
    return this.credentials.email !== this.credentials.email.toLowerCase();
  }

  get caseWarningText(): string | undefined {
    if (this.hasCaseWarning) {
      return this.$t(
        "Emails usually don't contain capitals, make sure you haven't made a typo."
      ) as string;
    }
    return undefined;
  }

  get caseWarningType(): string | undefined {
    if (this.hasCaseWarning) {
      return "is-warning";
    }
    return undefined;
  }
}
</script>

<style lang="scss" scoped>
.container .columns {
  margin: 1rem auto 3rem;
}
::v-deep .help.is-warning {
  color: #755033;
}
</style>
