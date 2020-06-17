<template>
  <li :class="{ active: sectionActive }">
    <router-link v-if="menuSection.to" :to="menuSection.to">{{ menuSection.title }}</router-link>
    <b v-else>{{ menuSection.title }}</b>
    <ul>
      <setting-menu-item :menu-item="item" v-for="item in menuSection.items" :key="item.title" />
    </ul>
  </li>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { ISettingMenuSection } from "@/types/setting-menu.model";
import SettingMenuItem from "@/components/Settings/SettingMenuItem.vue";
@Component({
  components: { SettingMenuItem },
})
export default class SettingMenuSection extends Vue {
  @Prop({ required: true, type: Object }) menuSection!: ISettingMenuSection;

  get sectionActive(): boolean | undefined {
    return (
      this.menuSection.items &&
      this.menuSection.items.some(({ to }) => to && to.name === this.$route.name)
    );
  }
}
</script>

<style lang="scss" scoped>
@import "@/variables.scss";

li {
  font-size: 1.3rem;
  background-color: $secondary;
  color: $background-color;
  margin: 2px auto;

  &.active {
    background-color: #fea72b;
  }

  a,
  b {
    cursor: pointer;
    margin: 5px 0;
    display: block;
    padding: 5px 10px;
    color: inherit;
    font-weight: 500;
  }
}
</style>
