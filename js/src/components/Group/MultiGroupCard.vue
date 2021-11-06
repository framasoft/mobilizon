<template>
  <div class="multi-card-group">
    <group-card
      class="group-card"
      v-for="group in groups"
      :group="group"
      :key="group.id"
    />
  </div>
</template>
<script lang="ts">
import { IGroup } from "@/types/actor";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import GroupCard from "./GroupCard.vue";
@Component({
  components: {
    GroupCard,
  },
})
export default class MultiGroupCard extends Vue {
  @Prop({ type: Array as PropType<IGroup[]>, required: true })
  groups!: IGroup[];
}
</script>
<style lang="scss" scoped>
.multi-card-group {
  display: grid;
  grid-auto-rows: 1fr;
  grid-column-gap: 30px;
  grid-row-gap: 30px;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  .group-card {
    height: 100%;
    display: flex;
    flex-direction: column;
  }
}
</style>
