<template>
  <aside class="section container">
    <h1 class="title">{{ $t("Settings") }}</h1>
    <div class="columns">
      <SettingsMenu class="column is-one-quarter-desktop" :menu="menu" />
      <div class="column">
        <nav class="breadcrumb" aria-label="breadcrumbs">
          <ul>
            <li
              v-for="route in routes.get($route.name)"
              :class="{ 'is-active': route.to.name === $route.name }"
              :key="route.to.name"
            >
              <router-link :to="{ name: route.to.name }">{{ route.title }}</router-link>
            </li>
          </ul>
        </nav>
        <router-view />
      </div>
    </div>
  </aside>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { Route } from "vue-router";
import SettingsMenu from "../components/Settings/SettingsMenu.vue";
import RouteName from "../router/name";
import { ISettingMenuSection } from "../types/setting-menu.model";
import { IPerson, Person } from "../types/actor";
import { IDENTITIES } from "../graphql/actor";

@Component({
  components: { SettingsMenu },
  apollo: {
    identities: {
      query: IDENTITIES,
      update: (data) => data.identities.map((identity: IPerson) => new Person(identity)),
    },
  },
})
export default class Settings extends Vue {
  RouteName = RouteName;

  menu: ISettingMenuSection[] = [];

  identities!: IPerson[];

  newIdentity!: ISettingMenuSection;

  mounted() {
    this.newIdentity = {
      title: this.$t("New profile") as string,
      to: { name: RouteName.CREATE_IDENTITY } as Route,
    };
    this.menu = [
      {
        title: this.$t("Account") as string,
        to: { name: RouteName.ACCOUNT_SETTINGS } as Route,
        items: [
          {
            title: this.$t("General") as string,
            to: { name: RouteName.ACCOUNT_SETTINGS_GENERAL } as Route,
          },
          {
            title: this.$t("Preferences") as string,
            to: { name: RouteName.PREFERENCES } as Route,
          },
          {
            title: this.$t("Email notifications") as string,
            to: { name: RouteName.NOTIFICATIONS } as Route,
          },
        ],
      },
      {
        title: this.$t("Profiles") as string,
        to: { name: RouteName.IDENTITIES } as Route,
        items: [this.newIdentity],
      },
      {
        title: this.$t("Moderation") as string,
        to: { name: RouteName.MODERATION } as Route,
        items: [
          {
            title: this.$t("Reports") as string,
            to: { name: RouteName.REPORTS } as Route,
            items: [
              {
                title: this.$t("Report") as string,
                to: { name: RouteName.REPORT } as Route,
              },
            ],
          },
          {
            title: this.$t("Moderation log") as string,
            to: { name: RouteName.REPORT_LOGS } as Route,
          },
        ],
      },
      {
        title: this.$t("Admin") as string,
        to: { name: RouteName.ADMIN } as Route,
        items: [
          {
            title: this.$t("Dashboard") as string,
            to: { name: RouteName.ADMIN_DASHBOARD } as Route,
          },
          {
            title: this.$t("Instance settings") as string,
            to: { name: RouteName.ADMIN_SETTINGS } as Route,
          },
          {
            title: this.$t("Federation") as string,
            to: { name: RouteName.RELAYS } as Route,
            items: [
              {
                title: this.$t("Followings") as string,
                to: { name: RouteName.RELAY_FOLLOWINGS } as Route,
              },
              {
                title: this.$t("Followers") as string,
                to: { name: RouteName.RELAY_FOLLOWERS } as Route,
              },
            ],
          },
          {
            title: this.$t("Users") as string,
            to: { name: RouteName.USERS } as Route,
          },
          {
            title: this.$t("Profiles") as string,
            to: { name: RouteName.PROFILES } as Route,
          },
        ],
      },
    ];
  }

  @Watch("identities")
  updateIdentities(identities: IPerson[]) {
    if (!identities) return;
    if (!this.menu[1].items) return;
    this.menu[1].items = [];
    this.menu[1].items.push(
      ...identities.map((identity: IPerson) => ({
        to: ({
          name: RouteName.UPDATE_IDENTITY,
          params: { identityName: identity.preferredUsername },
        } as unknown) as Route,
        title: `@${identity.preferredUsername}`,
      }))
    );
    this.menu[1].items.push(this.newIdentity);
  }

  get routes(): Map<string, Route[]> {
    return this.getPath(this.menu);
  }

  getPath(object: ISettingMenuSection[]) {
    function iter(menu: ISettingMenuSection[] | ISettingMenuSection, acc: ISettingMenuSection[]) {
      if (Array.isArray(menu)) {
        return menu.forEach((item: ISettingMenuSection) => {
          iter(item, acc.concat(item));
        });
      }
      if (menu.items && menu.items.length > 0) {
        return menu.items.forEach((item: ISettingMenuSection) => {
          iter(item, acc.concat(item));
        });
      }
      result.set(menu.to.name, acc);
    }

    const result = new Map();
    iter(object, []);
    return result;
  }
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
