<template>
  <div v-if="loggedUser">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ACCOUNT_SETTINGS }">{{
            $t("Account")
          }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.ACCOUNT_SETTINGS_GENERAL }">{{
            $t("General")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section>
      <div class="setting-title">
        <h2>{{ $t("Email") }}</h2>
      </div>
      <i18n
        tag="p"
        class="content"
        v-if="loggedUser"
        path="Your current email is {email}. You use it to log in."
      >
        <b slot="email">{{ loggedUser.email }}</b>
      </i18n>
      <b-message v-if="!canChangeEmail" type="is-warning" :closable="false">
        {{
          $t(
            "Your email address was automatically set based on your {provider} account.",
            {
              provider: providerName(loggedUser.provider),
            }
          )
        }}
      </b-message>
      <b-notification
        type="is-danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in changeEmailErrors"
        >{{ error }}</b-notification
      >
      <form
        @submit.prevent="resetEmailAction"
        ref="emailForm"
        class="form"
        v-if="canChangeEmail"
      >
        <b-field :label="$t('New email')">
          <b-input
            aria-required="true"
            required
            type="email"
            v-model="newEmail"
          />
        </b-field>
        <p class="help">{{ $t("You'll receive a confirmation email.") }}</p>
        <b-field :label="$t('Password')">
          <b-input
            aria-required="true"
            required
            type="password"
            password-reveal
            minlength="6"
            v-model="passwordForEmailChange"
          />
        </b-field>
        <button
          class="button is-primary"
          :disabled="!($refs.emailForm && $refs.emailForm.checkValidity())"
        >
          {{ $t("Change my email") }}
        </button>
      </form>
      <div class="setting-title">
        <h2>{{ $t("Password") }}</h2>
      </div>
      <b-message v-if="!canChangePassword" type="is-warning" :closable="false">
        {{
          $t(
            "You can't change your password because you are registered through {provider}.",
            {
              provider: providerName(loggedUser.provider),
            }
          )
        }}
      </b-message>
      <b-notification
        type="is-danger"
        has-icon
        aria-close-label="Close notification"
        role="alert"
        :key="error"
        v-for="error in changePasswordErrors"
        >{{ error }}</b-notification
      >
      <form
        @submit.prevent="resetPasswordAction"
        ref="passwordForm"
        class="form"
        v-if="canChangePassword"
      >
        <b-field :label="$t('Old password')">
          <b-input
            aria-required="true"
            required
            type="password"
            password-reveal
            minlength="6"
            v-model="oldPassword"
          />
        </b-field>
        <b-field :label="$t('New password')">
          <b-input
            aria-required="true"
            required
            type="password"
            password-reveal
            minlength="6"
            v-model="newPassword"
          />
        </b-field>
        <button
          class="button is-primary"
          :disabled="
            !($refs.passwordForm && $refs.passwordForm.checkValidity())
          "
        >
          {{ $t("Change my password") }}
        </button>
      </form>
      <div class="setting-title">
        <h2>{{ $t("Delete account") }}</h2>
      </div>
      <p class="content">
        {{ $t("Deleting my account will delete all of my identities.") }}
      </p>
      <b-button @click="openDeleteAccountModal" type="is-danger">
        {{ $t("Delete my account") }}
      </b-button>

      <b-modal
        :active.sync="isDeleteAccountModalActive"
        has-modal-card
        full-screen
        :can-cancel="false"
      >
        <section class="hero is-primary is-fullheight">
          <div class="hero-body has-text-centered">
            <div class="container">
              <div class="columns">
                <div
                  class="column is-one-third-desktop is-offset-one-third-desktop"
                >
                  <h1 class="title">
                    {{ $t("Deleting your Mobilizon account") }}
                  </h1>
                  <p class="content">
                    {{
                      $t(
                        "Are you really sure you want to delete your whole account? You'll lose everything. Identities, settings, events created, messages and participations will be gone forever."
                      )
                    }}
                    <br />
                    <b>{{
                      $t("There will be no way to recover your data.")
                    }}</b>
                  </p>
                  <p class="content" v-if="hasUserGotAPassword">
                    {{
                      $t("Please enter your password to confirm this action.")
                    }}
                  </p>
                  <form @submit.prevent="deleteAccount">
                    <b-field v-if="hasUserGotAPassword">
                      <b-input
                        type="password"
                        v-model="passwordForAccountDeletion"
                        password-reveal
                        icon="lock"
                        :placeholder="$t('Password')"
                      />
                    </b-field>
                    <b-button
                      native-type="submit"
                      type="is-danger"
                      size="is-large"
                    >
                      {{ $t("Delete everything") }}
                    </b-button>
                  </form>
                  <div class="cancel-button">
                    <b-button
                      type="is-light"
                      @click="isDeleteAccountModalActive = false"
                    >
                      {{ $t("Cancel") }}
                    </b-button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </b-modal>
    </section>
  </div>
</template>

<script lang="ts">
import { IAuthProvider } from "@/types/enums";
import { Component, Vue, Ref } from "vue-property-decorator";
import { Route } from "vue-router";
import {
  CHANGE_EMAIL,
  CHANGE_PASSWORD,
  DELETE_ACCOUNT,
  LOGGED_USER,
} from "../../graphql/user";
import RouteName from "../../router/name";
import { IUser } from "../../types/current-user.model";
import { logout, SELECTED_PROVIDERS } from "../../utils/auth";

@Component({
  apollo: {
    loggedUser: LOGGED_USER,
  },
})
export default class AccountSettings extends Vue {
  @Ref("passwordForm") readonly passwordForm!: HTMLElement;

  loggedUser!: IUser;

  passwordForEmailChange = "";

  newEmail = "";

  changeEmailErrors: string[] = [];

  oldPassword = "";

  newPassword = "";

  changePasswordErrors: string[] = [];

  isDeleteAccountModalActive = false;

  passwordForAccountDeletion = "";

  RouteName = RouteName;

  async resetEmailAction(): Promise<void> {
    this.changeEmailErrors = [];

    try {
      await this.$apollo.mutate({
        mutation: CHANGE_EMAIL,
        variables: {
          email: this.newEmail,
          password: this.passwordForEmailChange,
        },
      });

      this.$notifier.info(
        this.$t(
          "The account's email address was changed. Check your emails to verify it."
        ) as string
      );
      this.newEmail = "";
      this.passwordForEmailChange = "";
    } catch (err) {
      this.handleErrors("email", err);
    }
  }

  async resetPasswordAction(): Promise<void> {
    this.changePasswordErrors = [];

    try {
      await this.$apollo.mutate({
        mutation: CHANGE_PASSWORD,
        variables: {
          oldPassword: this.oldPassword,
          newPassword: this.newPassword,
        },
      });

      this.$notifier.success(
        this.$t("The password was successfully changed") as string
      );
    } catch (err) {
      this.handleErrors("password", err);
    }
  }

  protected openDeleteAccountModal(): void {
    this.passwordForAccountDeletion = "";
    this.isDeleteAccountModalActive = true;
  }

  async deleteAccount(): Promise<Route | void> {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_ACCOUNT,
        variables: {
          password: this.hasUserGotAPassword
            ? this.passwordForAccountDeletion
            : null,
        },
      });
      await logout(this.$apollo.provider.defaultClient);
      this.$buefy.notification.open({
        message: this.$t(
          "Your account has been successfully deleted"
        ) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });

      return await this.$router.push({ name: RouteName.HOME });
    } catch (err) {
      return this.handleErrors("delete", err);
    }
  }

  get canChangePassword(): boolean {
    return !this.loggedUser.provider;
  }

  get canChangeEmail(): boolean {
    return !this.loggedUser.provider;
  }

  // eslint-disable-next-line class-methods-use-this
  providerName(id: string): string {
    if (SELECTED_PROVIDERS[id]) {
      return SELECTED_PROVIDERS[id];
    }
    return id;
  }

  get hasUserGotAPassword(): boolean {
    return (
      this.loggedUser &&
      (this.loggedUser.provider == null ||
        this.loggedUser.provider === IAuthProvider.LDAP)
    );
  }

  private handleErrors(type: string, err: any) {
    console.error(err);

    if (err.graphQLErrors !== undefined) {
      err.graphQLErrors.forEach(({ message }: { message: string }) => {
        switch (type) {
          case "password":
            this.changePasswordErrors.push(message);
            break;
          case "email":
          default:
            this.changeEmailErrors.push(message);
            break;
        }
      });
    }
  }
}
</script>

<style lang="scss" scoped>
.cancel-button {
  margin-top: 2rem;
}

::v-deep .modal .modal-background {
  background-color: initial;
}
</style>
