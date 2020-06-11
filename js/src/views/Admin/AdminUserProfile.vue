<template>
  <div v-if="user" class="section">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{ $t("Admin") }}</router-link>
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
        <tr v-for="{ key, value, link, elements } in metadata" :key="key">
          <td>{{ key }}</td>
          <td v-if="elements && elements.length > 0">
            <ul v-for="{ value, link: elementLink, active } in elements" :key="value">
              <li>
                <router-link :to="elementLink">
                  <span v-if="active">{{ $t("{profile} (by default)", { profile: value }) }}</span>
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
          <td v-else>{{ value }}</td>
        </tr>
      </tbody>
    </table>
    <div class="buttons">
      <b-button @click="deleteAccount" v-if="!user.disabled" type="is-primary">{{
        $t("Suspend")
      }}</b-button>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { GET_USER, DELETE_ACCOUNT } from "../../graphql/user";
import { usernameWithDomain } from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import { IUser, ICurrentUserRole } from "../../types/current-user.model";
import { IPerson } from "../../types/actor";

@Component({
  apollo: {
    user: {
      query: GET_USER,
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
  @Prop({ required: true }) id!: String;

  user!: IUser;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  get metadata(): Array<object> {
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
        value: this.user.disabled ? this.$i18n.t("Disabled") : this.$t("Activated"),
      },
      {
        key: this.$i18n.t("Profiles"),
        elements: this.user.actors.map((actor: IPerson) => {
          return {
            link: { name: RouteName.ADMIN_PROFILE, params: { id: actor.id } },
            value: actor.name
              ? `${actor.name} (${actor.preferredUsername})`
              : actor.preferredUsername,
            active: this.user.defaultActor ? actor.id === this.user.defaultActor.id : false,
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
        key: this.$i18n.t("Participations"),
        value: this.user.participations.total,
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

  async deleteAccount() {
    await this.$apollo.mutate<{ suspendProfile: { id: string } }>({
      mutation: DELETE_ACCOUNT,
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
