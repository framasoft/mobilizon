<template>
  <div class="media">
    <div class="media-content">
      <div class="content">
        <i18n
          tag="p"
          path="You have been invited by {invitedBy} to the following group:"
        >
          <b slot="invitedBy">{{ member.invitedBy.name }}</b>
        </i18n>
      </div>
      <div class="media subfield">
        <div class="media-left">
          <figure class="image is-48x48" v-if="member.parent.avatar">
            <img class="is-rounded" :src="member.parent.avatar.url" alt="" />
          </figure>
          <b-icon v-else size="is-large" icon="account-group" />
        </div>
        <div class="media-content">
          <div class="level">
            <div class="level-left">
              <div class="level-item">
                <router-link
                  :to="{
                    name: RouteName.GROUP,
                    params: {
                      preferredUsername: usernameWithDomain(member.parent),
                    },
                  }"
                >
                  <h3>{{ member.parent.name }}</h3>
                  <p class="is-6 has-text-grey">
                    <span v-if="member.parent.domain">
                      {{
                        `@${member.parent.preferredUsername}@${member.parent.domain}`
                      }}
                    </span>
                    <span v-else>{{
                      `@${member.parent.preferredUsername}`
                    }}</span>
                  </p>
                </router-link>
              </div>
            </div>
            <div class="level-right">
              <div class="level-item">
                <b-button type="is-success" @click="$emit('accept', member.id)">
                  {{ $t("Accept") }}
                </b-button>
              </div>
              <div class="level-item">
                <b-button type="is-danger" @click="$emit('reject', member.id)">
                  {{ $t("Decline") }}
                </b-button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { usernameWithDomain } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";

@Component
export default class InvitationCard extends Vue {
  @Prop({ required: true }) member!: IMember;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
}
</script>

<style lang="scss" scoped>
.media:not(.subfield) {
  background: lighten($primary, 40%);
  padding: 10px;
}
</style>
