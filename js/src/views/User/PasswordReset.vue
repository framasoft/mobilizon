<template>
  <section class="section container">
    <div class="columns is-mobile is-centered">
      <div class="column is-half-desktop">
        <h1 class="title">
          {{ $t("Password reset") }}
        </h1>
        <b-message
          title="Error"
          type="is-danger"
          v-for="error in errors"
          :key="error"
          >{{ error }}</b-message
        >
        <form @submit="resetAction">
          <b-field :label="$t('Password')">
            <b-input
              aria-required="true"
              required
              type="password"
              password-reveal
              minlength="6"
              v-model="credentials.password"
            />
          </b-field>
          <b-field :label="$t('Password (confirmation)')">
            <b-input
              aria-required="true"
              required
              type="password"
              password-reveal
              minlength="6"
              v-model="credentials.password_confirmation"
            />
          </b-field>
          <button class="button is-primary">
            {{ $t("Reset my password") }}
          </button>
        </form>
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { validateRequiredField } from "../../utils/validators";
import { RESET_PASSWORD } from "../../graphql/auth";
import { saveUserData } from "../../utils/auth";
import { ILogin } from "../../types/login.model";
import RouteName from "../../router/name";

@Component
export default class PasswordReset extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  credentials = {
    password: "",
    passwordConfirmation: "",
  } as { password: string; passwordConfirmation: string };

  errors: string[] = [];

  rules = {
    passwordLength: (value: string): boolean | string =>
      value.length > 6 || "Password must be at least 6 characters long",
    required: validateRequiredField,
    passwordEqual: (value: string): boolean | string =>
      value === this.credentials.password || "Passwords must be the same",
  };

  get samePasswords(): boolean {
    return (
      this.rules.passwordLength(this.credentials.password) === true &&
      this.credentials.password === this.credentials.passwordConfirmation
    );
  }

  async resetAction(e: Event): Promise<void> {
    e.preventDefault();
    this.errors.splice(0);

    try {
      const { data } = await this.$apollo.mutate<{ resetPassword: ILogin }>({
        mutation: RESET_PASSWORD,
        variables: {
          password: this.credentials.password,
          token: this.token,
        },
      });
      if (data == null) {
        throw new Error("Data is undefined");
      }

      saveUserData(data.resetPassword);
      await this.$router.push({ name: RouteName.HOME });
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }: { message: any }) => {
        this.errors.push(message);
      });
    }
  }
}
</script>

<style lang="scss" scoped>
section.section.container {
  background: $white;
}
.container .columns {
  margin: 1rem auto 3rem;
}
</style>
