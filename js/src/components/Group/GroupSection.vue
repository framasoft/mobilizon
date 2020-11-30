<template>
  <section>
    <div class="group-section-title" :class="{ privateSection }">
      <h2>
        <b-icon :icon="icon" />
        <span>{{ title }}</span>
      </h2>
      <router-link :to="route">{{ $t("View all") }}</router-link>
    </div>
    <div class="main-slot">
      <slot></slot>
    </div>
    <div class="create-slot">
      <slot name="create"></slot>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { Route } from "vue-router";

@Component
export default class GroupSection extends Vue {
  @Prop({ required: true, type: String }) title!: string;

  @Prop({ required: true, type: String }) icon!: string;

  @Prop({ required: false, type: Boolean, default: true })
  privateSection!: boolean;

  @Prop({ required: true, type: Object }) route!: Route;
}
</script>
<style lang="scss" scoped>
section {
  display: flex;
  flex-direction: column;
  margin-bottom: 2rem;
  border: 2px solid $violet;
  min-height: 30vh;

  .create-slot {
    display: flex;
    justify-content: flex-end;
    padding-bottom: 0.5rem;
    padding-right: 0.5rem;
  }

  .main-slot {
    min-height: 5rem;
    padding: 5px;
    flex: 1;
  }
}

div.group-section-title {
  display: flex;
  align-items: stretch;
  background: $secondary;
  color: #3a384c;

  &.privateSection {
    color: $violet-2;
    background: $purple-2;
  }

  ::v-deep & > a {
    align-self: center;
    margin-right: 5px;
    color: $orange-3;
  }

  h2 {
    flex: 1;

    ::v-deep span {
      display: inline;
      padding: 3px 8px;
      font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial,
        serif;
      font-weight: 500;
      font-size: 30px;
      flex: 1;
    }

    ::v-deep span.icon {
      flex: 0;
      height: 100%;
    }
  }
}
</style>
