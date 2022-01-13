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
      <h2 class="text-lg font-bold">{{ $t("Details") }}</h2>
      <div class="flex flex-col">
        <div class="overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block py-2 min-w-full sm:px-2 lg:px-8">
            <div class="overflow-hidden shadow-md sm:rounded-lg">
              <table v-if="metadata.length > 0" class="min-w-full">
                <tbody>
                  <tr
                    class="odd:bg-white even:bg-gray-50 border-b odd:dark:bg-gray-800 even:dark:bg-gray-700 dark:border-gray-600"
                    v-for="{ key, value, link, elements, type } in metadata"
                    :key="key"
                  >
                    <td class="py-4 px-2 whitespace-nowrap dark:text-white">
                      {{ key }}
                    </td>
                    <td
                      v-if="elements && elements.length > 0"
                      class="py-4 px-2 text-sm text-gray-500 whitespace-nowrap dark:text-white"
                    >
                      <ul
                        v-for="{ value, link: elementLink, active } in elements"
                        :key="value"
                      >
                        <li>
                          <router-link :to="elementLink">
                            <span v-if="active">{{
                              $t("{profile} (by default)", { profile: value })
                            }}</span>
                            <span v-else>{{ value }}</span>
                          </router-link>
                        </li>
                      </ul>
                    </td>
                    <td
                      v-else-if="elements"
                      class="py-4 px-2 whitespace-nowrap dark:text-white"
                    >
                      {{ $t("None") }}
                    </td>
                    <td
                      v-else-if="link"
                      class="py-4 px-2 whitespace-nowrap dark:text-white"
                    >
                      <router-link :to="link">
                        {{ value }}
                      </router-link>
                    </td>
                    <td
                      v-else-if="type === 'code'"
                      class="py-4 px-2 whitespace-nowrap dark:text-white"
                    >
                      <code>{{ value }}</code>
                    </td>
                    <td
                      v-else-if="type === 'badge'"
                      class="py-4 px-2 whitespace-nowrap dark:text-white"
                    >
                      <span
                        class="bg-red-100 text-red-800 text-sm font-medium mr-2 px-2.5 py-0.5 rounded dark:bg-red-200 dark:text-red-900"
                      >
                        {{ value }}
                      </span>
                    </td>
                    <td
                      v-else
                      class="py-4 px-2 whitespace-nowrap dark:text-white"
                    >
                      {{ value }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold">{{ $t("Actions") }}</h2>
      <div class="buttons">
        <b-button
          @click="deleteAccount"
          v-if="!user.disabled"
          type="is-primary"
          >{{ $t("Suspend") }}</b-button
        >
      </div>
    </section>
    <section class="my-4">
      <h2 class="text-lg font-bold">{{ $t("Profiles") }}</h2>
      <div class="flex gap-4 flex-wrap">
        <router-link
          v-for="profile in profiles"
          :key="profile.id"
          class="flex-auto"
          :to="{ name: RouteName.ADMIN_PROFILE, params: { id: profile.id } }"
        >
          <actor-card
            :actor="profile"
            :full="true"
            :popover="false"
            :limit="false"
          />
        </router-link>
      </div>
    </section>
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
import { Component, Vue, Prop } from "vue-property-decorator";
import { Route } from "vue-router";
import { formatBytes } from "@/utils/datetime";
import { ICurrentUserRole } from "@/types/enums";
import { GET_USER, SUSPEND_USER } from "../../graphql/user";
import { IActor, usernameWithDomain } from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import { IUser } from "../../types/current-user.model";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import ActorCard from "../../components/Account/ActorCard.vue";
import { LANGUAGES_CODES } from "@/graphql/admin";

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

  get metadata(): Array<Record<string, unknown>> {
    if (!this.user) return [];
    return [
      {
        key: this.$i18n.t("Email"),
        value: this.user.email,
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
        type: "badge",
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
        type: "code",
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

  async deleteAccount(): Promise<Route> {
    await this.$apollo.mutate<{ suspendProfile: { id: string } }>({
      mutation: SUSPEND_USER,
      variables: {
        userId: this.id,
      },
    });
    return this.$router.push({ name: RouteName.USERS });
  }

  get profiles(): IActor[] {
    return this.user.actors;
  }

  get languageCode(): string | undefined {
    return this.user?.locale;
  }
}
</script>
