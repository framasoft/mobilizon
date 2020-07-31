<template>
  <div class="section container">
    <section class="hero">
      <div class="hero-body">
        <h1 class="title">
          {{ $t("Register an account on {instanceName}!", { instanceName: config.name }) }}
        </h1>
        <i18n tag="p" path="{instanceName} is an instance of the {mobilizon} software.">
          <b slot="instanceName">{{ config.name }}</b>
          <a href="https://joinmobilizon.org" target="_blank" slot="mobilizon">{{
            $t("Mobilizon")
          }}</a>
        </i18n>
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
            <div class="content" v-html="config.description"></div>
            <i18n path="Please read the instance's {fullRules}" tag="p">
              <router-link slot="fullRules" :to="{ name: RouteName.RULES }">{{
                $t("full rules")
              }}</router-link>
            </i18n>
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

            <b-checkbox required>
              <i18n tag="span" path="I agree to the {instanceRules} and {termsOfService}">
                <router-link slot="instanceRules" :to="{ name: RouteName.RULES }">{{
                  $t("instance rules")
                }}</router-link>
                <router-link slot="termsOfService" :to="{ name: RouteName.TERMS }">{{
                  $t("terms of service")
                }}</router-link>
              </i18n>
            </b-checkbox>

            <p class="control has-text-centered">
              <b-button
                type="is-primary"
                size="is-large"
                :disabled="sendingForm"
                native-type="submit"
              >
                {{ $t("Register") }}
              </b-button>
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
                >{{ $t("Login") }}</router-link
              >
            </p>

            <hr />
            <div class="control" v-if="config && config.auth.oauthProviders.length > 0">
              <auth-providers :oauthProviders="config.auth.oauthProviders" />
            </div>
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
import AuthProviders from "../../components/User/AuthProviders.vue";

@Component({
  components: { Subtitle, AuthProviders },
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

  sendingForm = false;

  RouteName = RouteName;

  config!: IConfig;

  async submit() {
    this.sendingForm = true;
    this.credentials.locale = this.$i18n.locale;
    try {
      this.errors = {};

      await this.$apollo.mutate({
        mutation: CREATE_USER,
        variables: this.credentials,
      });

      return this.$router.push({
        name: RouteName.REGISTER_PROFILE,
        params: { email: this.credentials.email },
      });
    } catch (error) {
      console.error(error);
      this.errors = error.graphQLErrors.reduce((acc: { [key: string]: any }, localError: any) => {
        acc[localError.details] = localError.message;
        return acc;
      }, {});
      this.sendingForm = false;
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
