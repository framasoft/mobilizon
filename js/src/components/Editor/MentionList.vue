<template>
  <div class="items">
    <button
      class="item"
      :class="{ 'is-selected': index === selectedIndex }"
      v-for="(item, index) in items"
      :key="index"
      @click="selectItem(index)"
    >
      {{ item }}
    </button>
  </div>
</template>

<script lang="ts">
import { Vue, Component, Prop, Watch } from "vue-property-decorator";

@Component
export default class MentionList extends Vue {
  @Prop({ type: Array, required: true }) items!: Array<any>;
  @Prop({ type: Function, required: true }) command!: any;

  selectedIndex = 0;

  @Watch("items")
  watchItems(): void {
    this.selectedIndex = 0;
  }

  onKeyDown({ event }: { event: KeyboardEvent }): boolean {
    if (event.key === "ArrowUp") {
      this.upHandler();
      return true;
    }

    if (event.key === "ArrowDown") {
      this.downHandler();
      return true;
    }

    if (event.key === "Enter") {
      this.enterHandler();
      return true;
    }

    return false;
  }

  upHandler(): void {
    this.selectedIndex =
      (this.selectedIndex + this.items.length - 1) % this.items.length;
  }

  downHandler(): void {
    this.selectedIndex = (this.selectedIndex + 1) % this.items.length;
  }

  enterHandler(): void {
    this.selectItem(this.selectedIndex);
  }

  selectItem(index: number): void {
    const item = this.items[index];

    if (item) {
      this.command({ id: item });
    }
  }
}
</script>

<style lang="scss" scoped>
.items {
  position: relative;
  border-radius: 0.25rem;
  background: white;
  color: rgba(black, 0.8);
  overflow: hidden;
  font-size: 0.9rem;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.1), 0px 10px 20px rgba(0, 0, 0, 0.1);
}

.item {
  display: block;
  width: 100%;
  text-align: left;
  background: transparent;
  border: none;
  padding: 0.2rem 0.5rem;

  &.is-selected,
  &:hover {
    color: #a975ff;
    background: rgba(#a975ff, 0.1);
  }
}
</style>
