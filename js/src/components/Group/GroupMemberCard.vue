<template>
  <div class="card">
    <div class="card-content">
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48">
            <img src="https://bulma.io/images/placeholders/96x96.png" alt="Placeholder image" />
          </figure>
        </div>
        <div class="media-content">
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(member.parent) },
            }"
          >
            <h3>{{ member.parent.name }}</h3>
            <p class="is-6 has-text-grey">
              <span v-if="member.parent.domain">{{
                `@${member.parent.preferredUsername}@${member.parent.domain}`
              }}</span>
              <span v-else>{{ `@${member.parent.preferredUsername}` }}</span>
            </p>
            <b-tag type="is-info">{{ member.role }}</b-tag>
          </router-link>
        </div>
      </div>
      <div class="content">
        <p>{{ member.parent.summary }}</p>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IMember, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";

@Component
export default class GroupMemberCard extends Vue {
  @Prop({ required: true }) member!: IMember;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
}
</script>
