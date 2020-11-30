<template>
  <div v-if="user" class="section">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{
            $t("Admin")
          }}</router-link>
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.USERS,
            }"
            >{{ $t("Users") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.ADMIN_USER_PROFILE,
              params: { id: user.id },
            }"
            >{{ user.email }}</router-link
          >
        </li>
      </ul>
    </nav>
    <table v-if="metadata.length > 0" class="table is-fullwidth">
      <tbody>
        <tr v-for="{ key, value, link, elements, type } in metadata" :key="key">
          <td>{{ key }}</td>
          <td v-if="elements && elements.length > 0">
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
          <td v-else-if="elements">
            {{ $t("None") }}
          </td>
          <td v-else-if="link">
            <router-link :to="link">
              {{ value }}
            </router-link>
          </td>
          <td v-else-if="type == 'code'">
            <code>{{ value }}</code>
          </td>
          <td v-else>{{ value }}</td>
        </tr>
      </tbody>
    </table>
    <div class="buttons">
      <b-button
        @click="deleteAccount"
        v-if="!user.disabled"
        type="is-primary"
        >{{ $t("Suspend") }}</b-button
      >
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { Route } from "vue-router";
import { formatBytes } from "@/utils/datetime";
import { ICurrentUserRole } from "@/types/enums";
import { GET_USER, SUSPEND_USER } from "../../graphql/user";
import { usernameWithDomain } from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import { IUser } from "../../types/current-user.model";
import { IPerson } from "../../types/actor";

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
  },
})
export default class AdminUserProfile extends Vue {
  @Prop({ required: true }) id!: string;

  user!: IUser;

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
        value: this.user.locale,
      },
      {
        key: this.$i18n.t("Role"),
        value: this.roleName(this.user.role),
      },
      {
        key: this.$i18n.t("Login status"),
        value: this.user.disabled
          ? this.$i18n.t("Disabled")
          : this.$t("Activated"),
      },
      {
        key: this.$i18n.t("Profiles"),
        elements: this.user.actors.map((actor: IPerson) => {
          return {
            link: { name: RouteName.ADMIN_PROFILE, params: { id: actor.id } },
            value: actor.name
              ? `${actor.name} (${actor.preferredUsername})`
              : actor.preferredUsername,
            active: this.user.defaultActor
              ? actor.id === this.user.defaultActor.id
              : false,
          };
        }),
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
        key: this.$i18n.t("Participations"),
        value: this.user.participations.total,
      },
      {
        key: this.$i18n.t("Uploaded media size"),
        value: formatBytes(this.user.mediaSize),
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
}
</script>

<style lang="scss" scoped>
table {
  margin: 2rem 0;
}
</style>
