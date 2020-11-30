<template>
  <div class="card">
    <div class="card-content">
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="group.avatar">
            <img class="is-rounded" :src="group.avatar.url" alt="" />
          </figure>
          <b-icon v-else size="is-large" icon="account-group" />
        </div>
        <div class="media-content">
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
          >
            <h3>{{ group.name }}</h3>
            <p class="is-6 has-text-grey">
              <span v-if="group.domain">{{
                `@${group.preferredUsername}@${group.domain}`
              }}</span>
              <span v-else>{{ `@${group.preferredUsername}` }}</span>
            </p>
          </router-link>
        </div>
      </div>
      <div class="content">
        <p>{{ group.summary }}</p>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";

@Component
export default class GroupCard extends Vue {
  @Prop({ required: true }) group!: IGroup;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
}
</script>
