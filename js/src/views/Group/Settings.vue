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
              :key="route.title"
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
import SettingsMenu from "@/components/Settings/SettingsMenu.vue";
import { ISettingMenuSection } from "@/types/setting-menu.model";
import { Route } from "vue-router";
import { IGroup, IPerson } from "@/types/actor";
import { FETCH_GROUP } from "@/graphql/actor";
import RouteName from "../../router/name";

@Component({
  components: { SettingsMenu },
  apollo: {
    group: {
      query: FETCH_GROUP,
    },
  },
})
export default class Settings extends Vue {
  RouteName = RouteName;

  menu: ISettingMenuSection[] = [];

  group!: IGroup[];

  mounted() {
    this.menu = [
      {
        title: this.$t("Settings") as string,
        to: { name: RouteName.GROUP_SETTINGS } as Route,
        items: [
          {
            title: this.$t("Public") as string,
            to: { name: RouteName.GROUP_PUBLIC_SETTINGS } as Route,
          },
          {
            title: this.$t("Members") as string,
            to: { name: RouteName.GROUP_MEMBERS_SETTINGS } as Route,
          },
        ],
      },
    ];
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
</style>
