<template>
  <div class="section container">
    <section class="hero">
      <div class="hero-body">
        <h1 class="title">{{ $t("Register an account on Mobilizon!") }}</h1>
      </div>
    </section>
    <section>
      <div class="columns">
        <div class="column">
          <div>
            <subtitle>{{ $t("Features") }}</subtitle>
            <div class="content">
              <ul>
                <li>{{ $t("Create and manage several identities from the same account") }}</li>
                <li>{{ $t("Create, edit or delete events") }}</li>
                <li>{{ $t("Register for an event by choosing one of your identities") }}</li>
              </ul>
            </div>
          </div>
          <router-link :to="{ name: RouteName.ABOUT }">{{ $t("Learn more") }}</router-link>
          <hr />
          <div class="content">
            <subtitle>{{ $t("About this instance") }}</subtitle>
            <div class="content">
              <p>{{ $t("Your local administrator resumed its policy:") }}</p>
              <ul>
                <li>{{ $t("Enjoy discovering Mobilizon!") }}</li>
              </ul>
            </div>
            <!--            <p>-->
            <!--              {{ $t('Please read the full rules') }}-->
            <!--            </p>-->
          </div>
        </div>
        <div class="column">
          <b-message type="is-warning" v-if="config.registrationsWhitelist">
            {{ $t("Registrations are restricted by whitelisting.") }}
          </b-message>
          <form v-on:submit.prevent="submit()">
            <b-field
              :label="$t('Email')"
              :type="errors.email ? 'is-danger' : null"
              :message="errors.email"
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
              :type="errors.password ? 'is-danger' : null"
              :message="errors.password"
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

            <p class="control has-text-centered">
              <button class="button is-primary is-large">{{ $t("Register") }}</button>
            </p>
            <p class="control">
              <router-link
                class="button is-text"
                :to="{ name: RouteName.RESEND_CONFIRMATION, params: { email: credentials.email } }"
                >{{ $t("Didn't receive the instructions ?") }}</router-link
              >
            </p>
            <p class="control">
              <router-link
                class="button is-text"
                :to="{
                  name: RouteName.LOGIN,
                  params: { email: credentials.email, password: credentials.password },
                }"
                :disabled="sendingValidation"
                >{{ $t("Login") }}</router-link
              >
            </p>
          </form>

          <div v-if="errors.length > 0">
            <b-message type="is-danger" v-for="error in errors" :key="error">{{ error }}</b-message>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { CREATE_USER } from "../../graphql/user";
import RouteName from "../../router/name";
import { IConfig } from "../../types/config.model";
import { CONFIG } from "../../graphql/config";
import Subtitle from "../../components/Utils/Subtitle.vue";

@Component({
  components: { Subtitle },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      title: this.$t("Register an account on Mobilizon!") as string,
      // all titles will be injected into this template
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

  credentials = {
    email: this.email,
    password: this.password,
    locale: "en",
  };

  errors: object = {};

  sendingValidation = false;

  validationSent = false;

  RouteName = RouteName;

  config!: IConfig;

  async submit() {
    this.credentials.locale = this.$i18n.locale;
    try {
      this.sendingValidation = true;
      this.errors = {};

      await this.$apollo.mutate({
        mutation: CREATE_USER,
        variables: this.credentials,
      });

      this.validationSent = true;

      await this.$router.push({
        name: RouteName.REGISTER_PROFILE,
        params: { email: this.credentials.email },
      });
    } catch (error) {
      console.error(error);
      this.errors = error.graphQLErrors.reduce((acc: { [key: string]: any }, localError: any) => {
        acc[localError.details] = localError.message;
        return acc;
      }, {});
    }
  }
}
</script>

<style lang="scss" scoped>
@import "../../variables";

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
</style>
