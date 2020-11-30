<template>
  <div class="section container">
    <h1 class="title">{{ $t("Settings") }}</h1>
    <div class="columns">
      <SettingsMenu class="column is-one-quarter-desktop" />
      <div class="column">
        <router-view />
      </div>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import SettingsMenu from "../components/Settings/SettingsMenu.vue";
import RouteName from "../router/name";
import { IPerson, Person } from "../types/actor";
import { IDENTITIES } from "../graphql/actor";
import { CURRENT_USER_CLIENT } from "../graphql/user";
import { ICurrentUser } from "../types/current-user.model";

@Component({
  components: { SettingsMenu },
  apollo: {
    identities: {
      query: IDENTITIES,
      update: (data) =>
        data.identities.map((identity: IPerson) => new Person(identity)),
    },
    currentUser: CURRENT_USER_CLIENT,
  },
})
export default class Settings extends Vue {
  RouteName = RouteName;

  identities!: IPerson[];

  currentUser!: ICurrentUser;
}
</script>

<style lang="scss" scoped>
aside.section {
  padding-top: 1rem;
}
.breadcrumb ul li a {
  text-decoration: none;
}
</style>
