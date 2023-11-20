<template>
  <div class="border rounded p-2 bg-mbz-yellow-alt-50 dark:bg-zinc-700">
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
    <div class="flex justify-between gap-2">
      <div class="flex gap-2">
        <div class="">
          <figure v-if="member.parent.avatar">
            <img
              class="rounded-full"
              :src="member.parent.avatar.url"
              alt=""
              height="48"
              width="48"
            />
          </figure>
          <AccountGroup :size="48" v-else />
        </div>
        <div class="mr-3">
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(member.parent),
              },
            }"
          >
            <p class="">{{ member.parent.name }}</p>
            <p class="text-sm">@{{ usernameWithDomain(member.parent) }}</p>
          </router-link>
        </div>
      </div>
      <div>
        <div class="flex gap-2">
          <div class="">
            <o-button variant="success" @click="$emit('accept', member.id)">
              {{ t("Accept") }}
            </o-button>
          </div>
          <div class="">
            <o-button variant="danger" @click="$emit('reject', member.id)">
              {{ t("Decline") }}
            </o-button>
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
import { useI18n } from "vue-i18n";

const { t } = useI18n({ useScope: "global" });

defineProps<{
  member: IMember;
}>();
</script>
