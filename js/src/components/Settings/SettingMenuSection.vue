<template>
  <li :class="{ active: sectionActive }">
    <router-link v-if="to" :to="to">{{ title }}</router-link>
    <b v-else>{{ title }}</b>
    <ul>
      <slot></slot>
    </ul>
  </li>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import SettingMenuItem from "@/components/Settings/SettingMenuItem.vue";
import { Route } from "vue-router";

@Component({
  components: { SettingMenuItem },
})
export default class SettingMenuSection extends Vue {
  @Prop({ required: false, type: String }) title!: string;

  @Prop({ required: true, type: Object }) to!: Route;

  get sectionActive(): boolean {
    if (this.$slots.default) {
      return this.$slots.default.some(
        ({
          componentOptions: {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            propsData: { to },
          },
        }) => to && to.name === this.$route.name
      );
    }
    return false;
  }
}
</script>

<style lang="scss" scoped>
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
