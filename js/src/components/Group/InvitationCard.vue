<template>
  <div class="card">
    <div class="card-content media">
      <div class="media-content">
        <div class="prose dark:prose-invert">
          <i18n-t
            tag="p"
            keypath="You have been invited by {invitedBy} to the following group:"
          >
            <template #invitedBy>
              <b>{{ member?.invitedBy?.name }}</b>
            </template>
          </i18n-t>
        </div>
        <div class="media subfield">
          <div class="media-left">
            <figure class="image is-48x48" v-if="member.parent.avatar">
              <img class="is-rounded" :src="member.parent.avatar.url" alt="" />
            </figure>
            <o-icon v-else size="large" icon="account-group" />
          </div>
          <div class="media-content">
            <div class="level">
              <div class="level-left">
                <div class="level-item mr-3">
                  <router-link
                    :to="{
                      name: RouteName.GROUP,
                      params: {
                        preferredUsername: usernameWithDomain(member.parent),
                      },
                    }"
                  >
                    <h3 class="is-size-5">{{ member.parent.name }}</h3>
                    <p class="is-size-7 has-text-grey-dark">
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
                  <o-button
                    variant="success"
                    @click="$emit('accept', member.id)"
                  >
                    {{ $t("Accept") }}
                  </o-button>
                </div>
                <div class="level-item">
                  <o-button
                    variant="danger"
                    @click="$emit('reject', member.id)"
                  >
                    {{ $t("Decline") }}
                  </o-button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { usernameWithDomain } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";

defineProps<{
  member: IMember;
}>();
</script>
