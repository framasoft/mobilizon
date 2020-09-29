<template>
  <aside class="section container">
    <h1 class="title">{{ $t("Settings") }}</h1>
    <div class="columns">
      <aside class="column is-one-quarter-desktop">
        <ul>
          <SettingMenuSection :title="$t('Settings')" :to="{ name: RouteName.GROUP_SETTINGS }">
            <SettingMenuItem
              :title="this.$t('Public')"
              :to="{ name: RouteName.GROUP_PUBLIC_SETTINGS }"
            />
            <SettingMenuItem
              :title="this.$t('Members')"
              :to="{ name: RouteName.GROUP_MEMBERS_SETTINGS }"
            />
          </SettingMenuSection>
        </ul>
      </aside>
      <div class="column">
        <router-view />
      </div>
    </div>
  </aside>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { IGroup } from "@/types/actor";
import RouteName from "../../router/name";
import SettingMenuSection from "../../components/Settings/SettingMenuSection.vue";
import SettingMenuItem from "../../components/Settings/SettingMenuItem.vue";

@Component({
  components: { SettingMenuSection, SettingMenuItem },
})
export default class Settings extends Vue {
  RouteName = RouteName;

  group!: IGroup[];
}
</script>

<style lang="scss" scoped>
aside.section {
  padding-top: 1rem;
}
</style>
