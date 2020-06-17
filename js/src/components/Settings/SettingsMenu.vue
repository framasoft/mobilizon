<template>
  <ul>
    <SettingMenuSection v-for="section in menuValue" :key="section.title" :menu-section="section" />
  </ul>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import SettingMenuSection from "@/components/Settings/SettingMenuSection.vue";
import { ISettingMenuSection } from "@/types/setting-menu.model";
@Component({
  components: { SettingMenuSection },
})
export default class SettingsMenu extends Vue {
  @Prop({ required: true, type: Array }) menu!: ISettingMenuSection[];

  get menuValue() {
    return this.menu;
  }
}
</script>
<style lang="scss" scoped>
/deep/ a {
  text-decoration: none;
}
</style>
