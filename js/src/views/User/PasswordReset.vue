<template>
  <section class="columns is-mobile is-centered">
    <div class="card column is-half-desktop">
      <h1>
        <translate>Password reset</translate>
      </h1>
      <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
      <form @submit="resetAction">
        <b-field label="Password">
          <b-input
            aria-required="true"
            required
            type="password"
            password-reveal
            minlength="6"
            v-model="credentials.password"
          />
        </b-field>
        <b-field label="Password (confirmation)">
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
          <translate>Reset my password</translate>
        </button>
      </form>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { validateRequiredField } from "@/utils/validators";
import { RESET_PASSWORD } from "@/graphql/auth";
import { saveUserData } from "@/utils/auth";
import { ILogin } from "@/types/login.model";

@Component
export default class PasswordReset extends Vue {
  @Prop({ type: String, required: true }) token!: string;

  credentials = {
    password: "",
    password_confirmation: ""
  } as { password: string; password_confirmation: string };
  errors: string[] = [];
  rules = {
    password_length: value =>
      value.length > 6 || "Password must be at least 6 characters long",
    required: validateRequiredField,
    password_equal: value =>
      value === this.credentials.password || "Passwords must be the same"
  };

  get samePasswords() {
    return (
      this.rules.password_length(this.credentials.password) === true &&
      this.credentials.password === this.credentials.password_confirmation
    );
  }

  async resetAction(e) {
    e.preventDefault();
    this.errors.splice(0);

    try {
      const result = await this.$apollo.mutate<{ resetPassword: ILogin }>({
        mutation: RESET_PASSWORD,
        variables: {
          password: this.credentials.password,
          token: this.token
        }
      });

      saveUserData(result.data.resetPassword);
      this.$router.push({ name: "Home" });
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }) => {
        this.errors.push(message);
      });
    }
  }
}
</script>
