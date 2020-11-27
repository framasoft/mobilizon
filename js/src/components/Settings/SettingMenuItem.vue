<template>
  <li class="setting-menu-item" :class="{ active: isActive }">
    <router-link v-if="to" :to="to">
      <span>{{ title }}</span>
    </router-link>
    <span v-else>{{ title }}</span>
  </li>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { Route } from "vue-router";

@Component
export default class SettingMenuItem extends Vue {
  @Prop({ required: false, type: String }) title!: string;

  @Prop({ required: true, type: Object }) to!: Route;

  get isActive(): boolean {
    if (!this.to) return false;
    if (this.to.name === this.$route.name) {
      if (this.to.params) {
        return this.to.params.identityName === this.$route.params.identityName;
      }
      return true;
    }
    return false;
  }
}
</script>

<style lang="scss" scoped>
li.setting-menu-item {
  font-size: 1.05rem;
  background-color: #fff1de;
  color: $background-color;
  margin: auto;

  span {
    padding: 5px 15px;
    display: block;
  }

  a {
    display: block;
    color: inherit;
  }

  &:hover,
  &.active {
    cursor: pointer;
    background-color: lighten(#fea72b, 10%);
  }
}
</style>
