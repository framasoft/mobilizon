<template>
  <section class="section container">
    <div class="columns is-mobile is-centered">
      <div class="column is-half-desktop">
        <h1 class="title">
          {{ $t("Forgot your password?") }}
        </h1>
        <p>
          {{
            $t(
              "Enter your email address below, and we'll email you instructions on how to change your password."
            )
          }}
        </p>
        <b-message
          title="Error"
          type="is-danger"
          v-for="error in errors"
          :key="error"
          @close="removeError(error)"
        >
          {{ error }}
        </b-message>
        <form @submit="sendResetPasswordTokenAction" v-if="!validationSent">
          <b-field :label="$t('Email address')">
            <b-input
              aria-required="true"
              required
              type="email"
              v-model="credentials.email"
            />
          </b-field>
          <p class="control">
            <b-button type="is-primary" native-type="submit">
              {{ $t("Submit") }}
            </b-button>
            <router-link
              :to="{ name: RouteName.LOGIN }"
              class="button is-text"
              >{{ $t("Cancel") }}</router-link
            >
          </p>
        </form>
        <div v-else>
          <b-message type="is-success" :closable="false" title="Success">
            {{
              $t("We just sent an email to {email}", {
                email: credentials.email,
              })
            }}
          </b-message>
          <b-message type="is-info">
            {{
              $t(
                "Please check your spam folder if you didn't receive the email."
              )
            }}
          </b-message>
        </div>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import {
  validateEmailField,
  validateRequiredField,
} from "../../utils/validators";
import { SEND_RESET_PASSWORD } from "../../graphql/auth";
import RouteName from "../../router/name";

@Component
export default class SendPasswordReset extends Vue {
  @Prop({ type: String, required: false, default: "" }) email!: string;

  credentials = {
    email: "",
  } as { email: string };

  validationSent = false;

  RouteName = RouteName;

  errors: string[] = [];

  state = {
    email: {
      status: null,
      msg: "",
    } as { status: boolean | null; msg: string },
  };

  rules = {
    required: validateRequiredField,
    email: validateEmailField,
  };

  mounted(): void {
    this.credentials.email = this.email;
  }

  removeError(message: string): void {
    this.errors.splice(this.errors.indexOf(message));
  }

  async sendResetPasswordTokenAction(e: Event): Promise<void> {
    e.preventDefault();

    try {
      await this.$apollo.mutate({
        mutation: SEND_RESET_PASSWORD,
        variables: {
          email: this.credentials.email,
        },
      });

      this.validationSent = true;
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }: { message: string }) => {
        if (this.errors.indexOf(message) < 0) {
          this.errors.push(message);
        }
      });
    }
  }

  resetState(): void {
    this.state = {
      email: {
        status: null,
        msg: "",
      },
    };
  }
}
</script>

<style lang="scss" scoped>
.container .columns {
  margin: 1rem auto 3rem;
}
</style>
