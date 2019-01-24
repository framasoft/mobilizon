<template>
  <div>
    <section class="hero">
      <h1 class="title">
        <translate>Welcome back!</translate>
      </h1>
    </section>
    <section>
      <div class="columns is-mobile is-centered">
        <div class="column is-half card">
          <b-message title="Error" type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
          <form @submit="loginAction">
            <b-field label="Email">
              <b-input aria-required="true" required type="email" v-model="credentials.email"/>
            </b-field>

            <b-field label="Password">
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
            <div class="control">
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
  </div>
</template>

<script lang="ts">
import Gravatar from "vue-gravatar";
import { Component, Prop, Vue } from "vue-property-decorator";
import { LOGIN } from "@/graphql/auth";
import { validateEmailField, validateRequiredField } from "@/utils/validators";
import { saveUserData } from "@/utils/auth";
import { ILogin } from "@/types/login.model";
import { UPDATE_CURRENT_USER_CLIENT } from "@/graphql/user";
import { onLogin } from "@/vue-apollo";

@Component({
  components: {
    "v-gravatar": Gravatar
  }
})
export default class Login extends Vue {
  @Prop({ type: String, required: false, default: "" }) email!: string;
  @Prop({ type: String, required: false, default: "" }) password!: string;

  credentials = {
    email: "",
    password: ""
  };
  validationSent = false;
  errors: string[] = [];
  rules = {
    required: validateRequiredField,
    email: validateEmailField
  };
  user: any;

  beforeCreate() {
    if (this.user) {
      this.$router.push("/");
    }
  }

  mounted() {
    this.credentials.email = this.email;
    this.credentials.password = this.password;
  }

  async loginAction(e: Event) {
    e.preventDefault();
    this.errors.splice(0);

    try {
      const result = await this.$apollo.mutate<{ login: ILogin }>({
        mutation: LOGIN,
        variables: {
          email: this.credentials.email,
          password: this.credentials.password
        }
      });

      saveUserData(result.data.login);

      await this.$apollo.mutate({
        mutation: UPDATE_CURRENT_USER_CLIENT,
        variables: {
          id: result.data.login.user.id,
          email: this.credentials.email
        }
      });

      onLogin(this.$apollo);

      this.$router.push({ name: "Home" });
    } catch (err) {
      console.error(err);
      err.graphQLErrors.forEach(({ message }) => {
        this.errors.push(message);
      });
    }
  }

  validEmail() {
    return this.rules.email(this.credentials.email) === true
      ? "v-gravatar"
      : "avatar";
  }
}
</script>
