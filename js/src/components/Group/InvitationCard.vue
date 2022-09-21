<template>
  <div class="">
    <div class="">
      <div class="">
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
        <div class="">
          <div class="">
            <figure v-if="member.parent.avatar">
              <img
                class="rounded"
                :src="member.parent.avatar.url"
                alt=""
                height="48"
                width="48"
              />
            </figure>
            <AccountGroup :size="48" v-else />
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
                    <h3 class="">{{ member.parent.name }}</h3>
                    <p class="">
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
              <div class="">
                <div class="">
                  <o-button
                    variant="success"
                    @click="$emit('accept', member.id)"
                  >
                    {{ $t("Accept") }}
                  </o-button>
                </div>
                <div class="">
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
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";

defineProps<{
  member: IMember;
}>();
</script>
