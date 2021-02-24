<template>
  <aside class="section container">
    <h1 class="title">{{ $t("Settings") }}</h1>
    <div class="columns">
      <aside class="column is-one-quarter-desktop">
        <ul>
          <SettingMenuSection
            :title="$t('Settings')"
            :to="{ name: RouteName.GROUP_SETTINGS }"
          >
            <SettingMenuItem
              :title="this.$t('Public')"
              :to="{ name: RouteName.GROUP_PUBLIC_SETTINGS }"
            />
            <SettingMenuItem
              :title="this.$t('Members')"
              :to="{ name: RouteName.GROUP_MEMBERS_SETTINGS }"
            />
            <SettingMenuItem
              :title="this.$t('Followers')"
              :to="{ name: RouteName.GROUP_FOLLOWERS_SETTINGS }"
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
import { Component } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";
import RouteName from "../../router/name";
import SettingMenuSection from "../../components/Settings/SettingMenuSection.vue";
import SettingMenuItem from "../../components/Settings/SettingMenuItem.vue";

@Component({
  components: { SettingMenuSection, SettingMenuItem },
})
export default class Settings extends mixins(GroupMixin) {
  RouteName = RouteName;
}
</script>

<style lang="scss" scoped>
aside.section {
  padding-top: 1rem;
}
.container.section {
  background: $white;
}
</style>
