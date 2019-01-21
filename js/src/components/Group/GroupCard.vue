<template>
  <div class="card">
    <div class="card-image" v-if="!group.bannerUrl">
      <figure class="image is-4by3">
        <img src="https://picsum.photos/g/400/200/">
      </figure>
    </div>
    <div class="card-content">
      <div class="content">
        <router-link :to="{ name: 'Group', params:{ uuid: group.uuid } }">
          <h2 class="title">{{ group.name ? group.name : group.preferredUsername }}</h2>
        </router-link>
      </div>
      <div v-if="!hideDetails">
        <p>{{ group.summary }}</p>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IGroup } from "../../types/actor.model";

@Component
export default class GroupCard extends Vue {
  @Prop({ required: true }) group!: IGroup;
  @Prop({ default: false }) hideDetails!: boolean;
}
</script>
