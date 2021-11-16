<template>
  <div class="section container">
    <section class="hero">
      <div class="hero-body">
        <h1 class="title">
          {{
            $t("Register an account on {instanceName}!", {
              instanceName: config.name,
            })
          }}
        </h1>
        <i18n
          tag="p"
          path="{instanceName} is an instance of the {mobilizon} software."
        >
          <b slot="instanceName">{{ config.name }}</b>
          <a
            href="https://joinmobilizon.org"
            target="_blank"
            class="out"
            slot="mobilizon"
            >{{ $t("Mobilizon") }}</a
          >
        </i18n>
      </div>
    </section>
    <section>
      <div class="columns">
        <div class="column">
          <div>
            <subtitle>{{ $t("Why create an account?") }}</subtitle>
            <div class="content">
              <ul>
                <li>{{ $t("To create and manage your events") }}</li>
                <li>
                  {{
                    $t(
                      "To create and manage multiples identities from a same account"
                    )
                  }}
                </li>
                <li>
                  {{
                    $t(
                      "To register for an event by choosing one of your identities"
                    )
                  }}
                </li>
                <li v-if="config.features.groups">
                  {{
                    $t(
                      "To create or join an group and start organizing with other people"
                    )
                  }}
                </li>
              </ul>
            </div>
          </div>
          <router-link class="out" :to="{ name: RouteName.ABOUT }">{{
            $t("Learn more")
          }}</router-link>
          <hr role="presentation" />
          <div class="content">
            <subtitle>{{
              $t("About {instance}", { instance: config.name })
            }}</subtitle>
            <div class="content" v-html="config.description"></div>
            <i18n
              path="Please read the {fullRules} published by {instance}'s administrators."
              tag="p"
            >
              <router-link slot="fullRules" :to="{ name: RouteName.RULES }">{{
                $t("full rules")
              }}</router-link>
              <b slot="instance">{{ config.name }}</b>
            </i18n>
          </div>
        </div>
        <div class="column">
          <b-message type="is-warning" v-if="config.registrationsAllowlist">
            {{ $t("Registrations are restricted by allowlisting.") }}
          </b-message>
          <form v-on:submit.prevent="submit()">
            <b-field
              :label="$t('Email')"
              :type="errorEmailType"
              :message="errorEmailMessages"
              label-for="email"
            >
              <b-input
                aria-required="true"
                required
                id="email"
                type="email"
                v-model="credentials.email"
                @blur="showGravatar = true"
                @focus="showGravatar = false"
              />
            </b-field>

            <b-field
              :label="$t('Password')"
              :type="errorPasswordType"
              :message="errorPasswordMessages"
              label-for="password"
            >
              <b-input
                aria-required="true"
                required
                id="password"
                type="password"
                password-reveal
                minlength="6"
                v-model="credentials.password"
              />
            </b-field>

            <b-checkbox required>
              <i18n
                tag="span"
                path="I agree to the {instanceRules} and {termsOfService}"
              >
                <router-link
                  class="out"
                  slot="instanceRules"
                  :to="{ name: RouteName.RULES }"
                  >{{ $t("instance rules") }}</router-link
                >
                <router-link
                  class="out"
                  slot="termsOfService"
                  :to="{ name: RouteName.TERMS }"
                  >{{ $t("terms of service") }}</router-link
                >
              </i18n>
            </b-checkbox>

            <p class="create-account control has-text-centered">
              <b-button
                type="is-primary"
                size="is-large"
                :disabled="sendingForm"
                native-type="submit"
              >
                {{ $t("Create an account") }}
              </b-button>
            </p>

            <p class="control has-text-centered">
              <router-link
                class="button is-text"
                :to="{
                  name: RouteName.RESEND_CONFIRMATION,
                  params: { email: credentials.email },
                }"
                >{{ $t("Didn't receive the instructions?") }}</router-link
              >
            </p>
            <p class="control has-text-centered">
              <router-link
                class="button is-text"
                :to="{
                  name: RouteName.LOGIN,
                  params: {
                    email: credentials.email,
                    password: credentials.password,
                  },
                }"
                >{{ $t("Login") }}</router-link
              >
            </p>

            <hr role="presentation" />
            <div
              class="control"
              v-if="config && config.auth.oauthProviders.length > 0"
            >
              <auth-providers :oauthProviders="config.auth.oauthProviders" />
            </div>
          </form>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { CREATE_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { IConfig } from "../../types/config.model";
import { CONFIG } from "../../graphql/config";
import Subtitle from "../../components/Utils/Subtitle.vue";
import AuthProviders from "../../components/User/AuthProviders.vue";
import { AbsintheGraphQLError } from "../../types/apollo";

type errorType = "is-danger" | "is-warning";
type errorMessage = { type: errorType; message: string };
type credentials = { email: string; password: string; locale: string };

@Component({
  components: { Subtitle, AuthProviders },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.title,
      titleTemplate: "%s | Mobilizon",
    };
  },
  apollo: {
    config: CONFIG,
  },
})
export default class Register extends Vue {
  @Prop({ type: String, required: false, default: "" }) email!: string;

  @Prop({ type: String, required: false, default: "" }) password!: string;

  credentials: credentials = {
    email: this.email,
    password: this.password,
    locale: "en",
  };

  emailErrors: errorMessage[] = [];
  passwordErrors: errorMessage[] = [];

  sendingForm = false;

  RouteName = RouteName;

  config!: IConfig;

  get title(): string {
    if (this.config) {
      return this.$t("Register an account on {instanceName}!", {
        instanceName: this.config.name,
      }) as string;
    }
    return "";
  }

  async submit(): Promise<void> {
    this.sendingForm = true;
    this.credentials.locale = this.$i18n.locale;
    try {
      this.emailErrors = [];
      this.passwordErrors = [];

      await this.$apollo.mutate({
        mutation: CREATE_USER,
        variables: this.credentials,
      });

      this.$router.push({
        name: RouteName.REGISTER_PROFILE,
        params: { email: this.credentials.email },
      });
    } catch (error: any) {
      error.graphQLErrors.forEach(
        ({ field, message }: AbsintheGraphQLError) => {
          switch (field) {
            case "email":
              this.emailErrors.push({
                type: "is-danger" as errorType,
                message: message[0] as string,
              });
              break;
            case "password":
              this.passwordErrors.push({
                type: "is-danger" as errorType,
                message: message[0] as string,
              });
              break;
            default:
          }
        }
      );

      this.sendingForm = false;
    }
  }

  @Watch("credentials", { deep: true })
  watchCredentials(credentials: credentials): void {
    if (credentials.email !== credentials.email.toLowerCase()) {
      const error = {
        type: "is-warning" as errorType,
        message: this.$t(
          "Emails usually don't contain capitals, make sure you haven't made a typo."
        ) as string,
      };
      this.emailErrors = [error];
      this.$forceUpdate();
    }
  }

  maxErrorType(errors: errorMessage[]): errorType | undefined {
    if (!errors || errors.length === 0) return undefined;
    return errors.reduce<errorType>((acc, error) => {
      if (error.type === "is-danger" || acc === "is-danger") return "is-danger";
      return "is-warning";
    }, "is-warning");
  }

  get errorEmailType(): errorType | undefined {
    return this.maxErrorType(this.emailErrors);
  }

  get errorPasswordType(): errorType | undefined {
    return this.maxErrorType(this.passwordErrors);
  }

  get errorEmailMessages(): string[] {
    return this.emailErrors.map(({ message }) => message);
  }

  get errorPasswordMessages(): string[] {
    return this.passwordErrors?.map(({ message }) => message);
  }
}
</script>

<style lang="scss" scoped>
.avatar-enter-active {
  transition: opacity 1s ease;
}

.avatar-enter,
.avatar-leave-to {
  opacity: 0;
}

.avatar-leave {
  display: none;
}

.container .columns {
  margin: 1rem auto 3rem;
}

h2.title {
  color: $primary;
  font-size: 2.5rem;
  text-decoration: underline;
  text-decoration-color: $secondary;
  display: inline;
}

p.create-account {
  ::v-deep button {
    margin: 1rem auto 2rem;
  }
}
::v-deep .help.is-warning {
  color: #755033;
}
</style>
