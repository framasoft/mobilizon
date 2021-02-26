<template>
  <div class="observer" />
</template>

<script lang="ts">
import "intersection-observer";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component
export default class Observer extends Vue {
  @Prop({ required: false, default: () => ({}) }) options!: Record<string, any>;

  observer!: IntersectionObserver;
  mounted(): void {
    this.observer = new IntersectionObserver(([entry]) => {
      if (entry && entry.isIntersecting) {
        this.$emit("intersect");
      }
    }, this.options);

    this.observer.observe(this.$el);
  }

  destroyed(): void {
    this.observer.disconnect();
  }
}
</script>
