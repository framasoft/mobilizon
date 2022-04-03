<template>
  <div v-if="user" class="section">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: $t('Admin') },
        {
          name: RouteName.USERS,
          text: $t('Users'),
        },
        {
          name: RouteName.ADMIN_USER_PROFILE,
          params: { id: user.id },
          text: user.email,
        },
      ]"
    />

    <section>
      <h2 class="text-lg font-bold mb-3">{{ $t("Details") }}</h2>
      <div class="flex flex-col">
        <div class="overflow-x-auto sm:-mx-6">
          <div class="inline-block py-2 min-w-full sm:px-2">
            <div class="overflow-hidden shadow-md sm:rounded-lg">
              <table v-if="metadata.length > 0" class="min-w-full">
                <tbody>
                  <tr
                    class="odd:bg-white even:bg-gray-50 border-b"
                    v-for="{ key, value, link, type } in metadata"
                    :key="key"
                  >
                    <td class="py-4 px-2 whitespace-nowrap align-middle">
                      {{ key }}
                    </td>
                    <td v-if="link" class="py-4 px-2 whitespace-nowrap">
                      <router-link :to="link">
                        {{ value }}
                      </router-link>
                    </td>
                    <td
                      v-else-if="type === 'ip'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <code>{{ value }}</code>
                    </td>
                    <td
                      v-else-if="type === 'role'"
                      class="py-4 px-2 whitespace-nowrap"
                    >
                      <span
                        :class="{
                          'bg-red-100 text-red-800':
                            user.role == ICurrentUserRole.ADMINISTRATOR,
                          'bg-yellow-100 text-yellow-800':
                            user.role == ICurrentUserRole.MODERATOR,
                          'bg-blue-100 text-blue-800':
                            user.role == ICurrentUserRole.USER,
                        }"
                        class="text-sm font-medium mr-2 px-2.5 py-0.5 rounded"
                      >
                        {{ value }}
                      </span>
                    </td>
                    <td v-else class="py-4 px-2 align-middle">
                      {{ value }}
                    </td>
                    <td
                      v-if="type === 'email'"
                      class="py-4 px-2 whitespace-nowrap flex flex flex-col items-start"
                    >
                      <b-button
                        size="is-small"
                        v-if="!user.disabled"
                        @click="isEmailChangeModalActive = true"
                        type="is-text"
                        icon-left="pencil"
                        >{{ $t("Change email") }}</b-button
                      >
                      <b-button
                        tag="router-link"
                        :to="{
                          name: RouteName.USERS,
                          query: { emailFilter: `@${userEmailDomain}` },
                        }"
                        size="is-small"
                        type="is-text"
                        icon-left="magnify"
                        >{{
                          $t("Other users with the same email domain")
                        }}</b-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'confirmed'"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <b-button
                        size="is-small"
                        v-if="!user.confirmedAt || user.disabled"
                        @click="isConfirmationModalActive = true"
                        type="is-text"
                        icon-left="check"
                        >{{ $t("Confirm user") }}</b-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'role'"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <b-button
                        size="is-small"
                        v-if="!user.disabled"
                        @click="isRoleChangeModalActive = true"
                        type="is-text"
                        icon-left="chevron-double-up"
                        >{{ $t("Change role") }}</b-button
                      >
                    </td>
                    <td
                      v-else-if="type === 'ip' && user.currentSignInIp"
                      class="py-4 px-2 whitespace-nowrap flex items-center"
                    >
                      <b-button
                        tag="router-link"
                        :to="{
                          name: RouteName.USERS,
                          query: { ipFilter: user.currentSignInIp },
                        }"
                        size="is-small"
                        type="is-text"
                        icon-left="web"
                        >{{
                          $t("Other users with the same IP address")
                        }}</b-button
                      >
                    </td>
                    <td v-else></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold mb-3">{{ $t("Profiles") }}</h2>
      <div
        class="flex flex-wrap justify-center sm:justify-start gap-4"
        v-if="profiles.length > 0"
      >
        <router-link
          v-for="profile in profiles"
          :key="profile.id"
          :to="{ name: RouteName.ADMIN_PROFILE, params: { id: profile.id } }"
        >
          <actor-card
            :actor="profile"
            :full="true"
            :popover="false"
            :limit="true"
          />
        </router-link>
      </div>
      <empty-content v-else-if="!$apollo.loading" :inline="true" icon="account">
        {{ $t("This user doesn't have any profiles") }}
      </empty-content>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold mb-3">{{ $t("Actions") }}</h2>
      <div class="buttons" v-if="!user.disabled">
        <b-button @click="suspendAccount" type="is-danger">{{
          $t("Suspend")
        }}</b-button>
      </div>
      <div
        v-else
        class="p-4 mb-4 text-sm text-red-700 bg-red-100 rounded-lg"
        role="alert"
      >
        {{ $t("The user has been disabled") }}
      </div>
    </section>
    <b-modal
      :active="isEmailChangeModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="$t('Edit user email')"
      :close-button-aria-label="$t('Close')"
      aria-modal
    >
      <template>
        <form @submit.prevent="updateUserEmail">
          <div class="modal-card" style="width: auto">
            <header class="modal-card-head">
              <p class="modal-card-title">{{ $t("Change user email") }}</p>
              <button
                type="button"
                class="delete"
                @click="isEmailChangeModalActive = false"
              />
            </header>
            <section class="modal-card-body">
              <b-field :label="$t('Previous email')">
                <b-input type="email" :value="user.email" disabled> </b-input>
              </b-field>
              <b-field :label="$t('New email')">
                <b-input
                  type="email"
                  v-model="newUser.email"
                  :placeholder="$t('new@email.com')"
                  required
                >
                </b-input>
              </b-field>
              <b-checkbox v-model="newUser.notify">{{
                $t("Notify the user of the change")
              }}</b-checkbox>
            </section>
            <footer class="modal-card-foot">
              <b-button @click="isEmailChangeModalActive = false">{{
                $t("Close")
              }}</b-button>
              <b-button native-type="submit" type="is-primary">{{
                $t("Change email")
              }}</b-button>
            </footer>
          </div>
        </form>
      </template>
    </b-modal>
    <b-modal
      :active="isRoleChangeModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="$t('Edit user email')"
      :close-button-aria-label="$t('Close')"
      aria-modal
    >
      <template>
        <form @submit.prevent="updateUserRole">
          <div class="modal-card" style="width: auto">
            <header class="modal-card-head">
              <p class="modal-card-title">{{ $t("Change user role") }}</p>
              <button
                type="button"
                class="delete"
                @click="isRoleChangeModalActive = false"
              />
            </header>
            <section class="modal-card-body">
              <b-field>
                <b-radio
                  v-model="newUser.role"
                  :native-value="ICurrentUserRole.ADMINISTRATOR"
                >
                  {{ $t("Administrator") }}
                </b-radio>
              </b-field>
              <b-field>
                <b-radio
                  v-model="newUser.role"
                  :native-value="ICurrentUserRole.MODERATOR"
                >
                  {{ $t("Moderator") }}
                </b-radio>
              </b-field>
              <b-field>
                <b-radio
                  v-model="newUser.role"
                  :native-value="ICurrentUserRole.USER"
                >
                  {{ $t("User") }}
                </b-radio>
              </b-field>
              <b-checkbox v-model="newUser.notify">{{
                $t("Notify the user of the change")
              }}</b-checkbox>
            </section>
            <footer class="modal-card-foot">
              <b-button @click="isRoleChangeModalActive = false">{{
                $t("Close")
              }}</b-button>
              <b-button native-type="submit" type="is-primary">{{
                $t("Change role")
              }}</b-button>
            </footer>
          </div>
        </form>
      </template>
    </b-modal>
    <b-modal
      :active="isConfirmationModalActive"
      has-modal-card
      trap-focus
      :destroy-on-hide="false"
      aria-role="dialog"
      :aria-label="$t('Edit user email')"
      :close-button-aria-label="$t('Close')"
      aria-modal
    >
      <template>
        <form @submit.prevent="confirmUser">
          <div class="modal-card" style="width: auto">
            <header class="modal-card-head">
              <p class="modal-card-title">{{ $t("Confirm user") }}</p>
              <button
                type="button"
                class="delete"
                @click="isConfirmationModalActive = false"
              />
            </header>
            <section class="modal-card-body">
              <b-checkbox v-model="newUser.notify">{{
                $t("Notify the user of the change")
              }}</b-checkbox>
            </section>
            <footer class="modal-card-foot">
              <b-button @click="isConfirmationModalActive = false">{{
                $t("Close")
              }}</b-button>
              <b-button native-type="submit" type="is-primary">{{
                $t("Confirm user")
              }}</b-button>
            </footer>
          </div>
        </form>
      </template>
    </b-modal>
  </div>
  <empty-content v-else-if="!$apollo.loading" icon="account">
    {{ $t("This user was not found") }}
    <template #desc>
      <b-button
        type="is-text"
        tag="router-link"
        :to="{ name: RouteName.USERS }"
        >{{ $t("Back to user list") }}</b-button
      >
    </template>
  </empty-content>
</template>
<script lang="ts">
import { Component, Vue, Prop, Watch } from "vue-property-decorator";
import { formatBytes } from "@/utils/datetime";
import { ICurrentUserRole } from "@/types/enums";
import { GET_USER, SUSPEND_USER } from "../../graphql/user";
import { IActor, usernameWithDomain } from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import { IUser } from "../../types/current-user.model";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import { ADMIN_UPDATE_USER, LANGUAGES_CODES } from "@/graphql/admin";

@Component({
  apollo: {
    user: {
      query: GET_USER,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.id,
        };
      },
      skip() {
        return !this.id;
      },
    },
    languages: {
      query: LANGUAGES_CODES,
      variables() {
        return {
          codes: [this.languageCode],
        };
      },
      skip() {
        return !this.languageCode;
      },
    },
  },
  metaInfo() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const { user } = this;
    return {
      title: user?.email,
    };
  },
  components: {
    EmptyContent,
    ActorCard,
  },
})
export default class AdminUserProfile extends Vue {
  @Prop({ required: true }) id!: string;

  user!: IUser;

  languages!: Array<{ code: string; name: string }>;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  ICurrentUserRole = ICurrentUserRole;

  isEmailChangeModalActive = false;

  isRoleChangeModalActive = false;

  isConfirmationModalActive = false;

  newUser = {
    email: "",
    role: this?.user?.role,
    confirm: false,
    notify: true,
  };

  get metadata(): Array<Record<string, unknown>> {
    if (!this.user) return [];
    return [
      {
        key: this.$i18n.t("Email"),
        value: this.user.email,
        type: "email",
      },
      {
        key: this.$i18n.t("Language"),
        value: this.languages
          ? this.languages[0].name
          : this.$i18n.t("Unknown"),
      },
      {
        key: this.$i18n.t("Role"),
        value: this.roleName(this.user.role),
        type: "role",
      },
      {
        key: this.$i18n.t("Login status"),
        value: this.user.disabled
          ? this.$i18n.t("Disabled")
          : this.$t("Activated"),
      },
      {
        key: this.$i18n.t("Confirmed"),
        value:
          this.$options.filters && this.user.confirmedAt
            ? this.$options.filters.formatDateTimeString(this.user.confirmedAt)
            : this.$i18n.t("Not confirmed"),
        type: "confirmed",
      },
      {
        key: this.$i18n.t("Last sign-in"),
        value:
          this.$options.filters && this.user.currentSignInAt
            ? this.$options.filters.formatDateTimeString(
                this.user.currentSignInAt
              )
            : this.$t("Unknown"),
      },
      {
        key: this.$i18n.t("Last IP adress"),
        value: this.user.currentSignInIp || this.$t("Unknown"),
        type: this.user.currentSignInIp ? "ip" : undefined,
      },
      {
        key: this.$i18n.t("Total number of participations"),
        value: this.user.participations.total,
      },
      {
        key: this.$i18n.t("Uploaded media total size"),
        value: formatBytes(
          this.user.mediaSize,
          2,
          this.$i18n.t("0 Bytes") as string
        ),
      },
    ];
  }

  roleName(role: ICurrentUserRole): string {
    switch (role) {
      case ICurrentUserRole.ADMINISTRATOR:
        return this.$t("Administrator") as string;
      case ICurrentUserRole.MODERATOR:
        return this.$t("Moderator") as string;
      case ICurrentUserRole.USER:
      default:
        return this.$t("User") as string;
    }
  }

  async suspendAccount(): Promise<void> {
    this.$buefy.dialog.confirm({
      title: this.$t("Suspend the account?") as string,
      message: this.$t(
        "Do you really want to suspend this account? All of the user's profiles will be deleted."
      ) as string,
      confirmText: this.$t("Suspend the account") as string,
      cancelText: this.$t("Cancel") as string,
      type: "is-danger",
      onConfirm: async () => {
        await this.$apollo.mutate<{ suspendProfile: { id: string } }>({
          mutation: SUSPEND_USER,
          variables: {
            userId: this.id,
          },
        });
        return this.$router.push({ name: RouteName.USERS });
      },
    });
  }

  get profiles(): IActor[] {
    return this.user.actors;
  }

  get languageCode(): string | undefined {
    return this.user?.locale;
  }

  async confirmUser() {
    this.isConfirmationModalActive = false;
    await this.updateUser({
      confirmed: true,
      notify: this.newUser.notify,
    });
  }

  async updateUserRole() {
    this.isRoleChangeModalActive = false;
    await this.updateUser({
      role: this.newUser.role,
      notify: this.newUser.notify,
    });
  }

  async updateUserEmail() {
    this.isEmailChangeModalActive = false;
    await this.updateUser({
      email: this.newUser.email,
      notify: this.newUser.notify,
    });
  }

  async updateUser(properties: {
    email?: string;
    notify: boolean;
    confirmed?: boolean;
    role?: ICurrentUserRole;
  }) {
    await this.$apollo.mutate<{ adminUpdateUser: IUser }>({
      mutation: ADMIN_UPDATE_USER,
      variables: {
        id: this.id,
        ...properties,
      },
    });
  }

  @Watch("user")
  resetCurrentUserRole(
    updatedUser: IUser | undefined,
    oldUser: IUser | undefined
  ) {
    if (updatedUser?.role !== oldUser?.role) {
      this.newUser.role = updatedUser?.role;
    }
  }

  get userEmailDomain(): string | undefined {
    if (this?.user?.email) {
      return this?.user?.email.split("@")[1];
    }
    return undefined;
  }
}
</script>
