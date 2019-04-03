<template>
  <div class="card">
    <div class="card-image" v-if="!group.bannerUrl">
      <figure class="image is-4by3">
        <img src="https://picsum.photos/g/400/200/">
      </figure>
    </div>
    <div class="card-content">
      <div class="content">
        <router-link :to="{ name: RouteName.GROUP, params:{ preferredUsername: group.preferredUsername } }">
          <h2 class="title">{{ group.displayName() }}</h2>
        </router-link>
      </div>
      <div>
        <p>{{ group.summary }}</p>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { Group } from '@/types/actor.model';
import { RouteName } from '@/router';

@Component
export default class GroupCard extends Vue {
  @Prop({ required: true }) group!: Group;

  RouteName = RouteName;
}
</script>
