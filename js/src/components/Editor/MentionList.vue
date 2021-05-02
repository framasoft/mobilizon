<template>
  <div class="items">
    <button
      class="item"
      :class="{ 'is-selected': index === selectedIndex }"
      v-for="(item, index) in items"
      :key="index"
      @click="selectItem(index)"
    >
      <actor-card :actor="item" />
    </button>
  </div>
</template>

<script lang="ts">
import { Vue, Component, Prop, Watch } from "vue-property-decorator";
import { displayName, usernameWithDomain } from "@/types/actor/actor.model";
import { IPerson } from "@/types/actor";
import ActorCard from "../../components/Account/ActorCard.vue";

@Component({
  components: {
    ActorCard,
  },
})
export default class MentionList extends Vue {
  @Prop({ type: Array, required: true }) items!: Array<IPerson>;
  @Prop({ type: Function, required: true }) command!: any;

  selectedIndex = 0;

  displayName = displayName;

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
      this.command({ id: usernameWithDomain(item) });
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
  padding: 0.5rem 0.75rem;

  &.is-selected,
  &:hover {
    color: $background-color;
    background: rgba($background-color, 0.1);
  }
}
</style>
