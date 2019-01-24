<template>
  <div>
    <section class="hero">
      <div class="hero-body">
        <h1 class="title">
          <translate>Register an account on Mobilizon!</translate>
        </h1>
      </div>
    </section>
    <section>
      <div class="container">
        <div class="columns is-mobile">
          <div class="column">
            <div class="content">
              <h2 class="subtitle" v-translate>Features</h2>
              <ul>
                <li v-translate>Create your communities and your events</li>
                <li v-translate>Other stuff…</li>
              </ul>
            </div>
            <p v-translate>
              Learn more on
              <a target="_blank" href="https://joinmobilizon.org">joinmobilizon.org</a>
            </p>
            <hr>
            <div class="content">
              <h2 class="subtitle" v-translate>About this instance</h2>
              <p>
                <translate>Your local administrator resumed it's policy:</translate>
              </p>
              <ul>
                <li v-translate>Please be nice to each other</li>
                <li v-translate>meditate a bit</li>
              </ul>
              <p>
                <translate>Please read the full rules</translate>
              </p>
            </div>
          </div>
          <div class="column">
            <form v-if="!validationSent">
              <div class="columns is-mobile is-centered">
                <div class="column is-narrow">
                  <figure class="image is-64x64">
                    <transition name="avatar">
                      <v-gravatar v-bind="{email: credentials.email}" default-img="mp"></v-gravatar>
                    </transition>
                  </figure>
                </div>
              </div>

              <b-field label="Email">
                <b-input
                  aria-required="true"
                  required
                  type="email"
                  v-model="credentials.email"
                  @blur="showGravatar = true"
                  @focus="showGravatar = false"
                />
              </b-field>

              <b-field label="Username">
                <b-input aria-required="true" required v-model="credentials.username"/>
              </b-field>

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

              <b-field grouped>
                <div class="control">
                  <button type="button" class="button is-primary" @click="submit()">
                    <translate>Register</translate>
                  </button>
                </div>
                <div class="control">
                  <router-link
                    class="button is-text"
                    :to="{ name: 'ResendConfirmation', params: { email: credentials.email }}"
                  >
                    <translate>Didn't receive the instructions ?</translate>
                  </router-link>
                </div>
                <div class="control">
                  <router-link
                    class="button is-text"
                    :to="{ name: 'Login', params: { email: credentials.email, password: credentials.password }}"
                    :disabled="validationSent"
                  >
                    <translate>Login</translate>
                  </router-link>
                </div>
              </b-field>
            </form>

            <div v-if="validationSent">
              <b-message title="Success" type="is-success">
                <h2>
                  <translate>A validation email was sent to %{email}</translate>
                </h2>
                <p>
                  <translate>Before you can login, you need to click on the link inside it to validate your account</translate>
                </p>
              </b-message>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import Gravatar from "vue-gravatar";
import { CREATE_USER } from "@/graphql/user";
import { Component, Prop, Vue } from "vue-property-decorator";
import { MOBILIZON_INSTANCE_HOST } from "@/api/_entrypoint";

@Component({
  components: {
    "v-gravatar": Gravatar
  }
})
export default class Register extends Vue {
  @Prop({ type: String, required: false, default: "" }) email!: string;
  @Prop({ type: String, required: false, default: "" }) password!: string;

  credentials = {
    username: "",
    email: this.email,
    password: this.password
  } as { username: string; email: string; password: string };
  errors: string[] = [];
  validationSent: boolean = false;
  showGravatar: boolean = false;

  host() {
    return MOBILIZON_INSTANCE_HOST;
  }

  validEmail() {
    return this.credentials.email.includes("@") === true
      ? "v-gravatar"
      : "avatar";
  }

  async submit() {
    try {
      this.validationSent = true;
      await this.$apollo.mutate({
        mutation: CREATE_USER,
        variables: this.credentials
      });
    } catch (error) {
      console.error(error);
    }
  }
}
</script>

<style lang="scss">
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
</style>
