<template>
  <div class="rounded shadow-lg bg-white dark:bg-mbz-purple dark:text-white">
    <div
      class="bg-mbz-yellow-alt-50 text-black flex items-center gap-1 p-2 rounded-t-lg"
      dir="auto"
    >
      <figure class="" v-if="member.actor.avatar">
        <img
          class="rounded-xl"
          :src="member.actor.avatar.url"
          alt=""
          width="24"
          height="24"
        />
      </figure>
      <AccountCircle v-else :size="24" />
      {{ displayNameAndUsername(member.actor) }}
    </div>
    <div class="flex items-center gap-2 p-2 pr-4" dir="auto">
      <div class="flex-1">
        <div class="p-2 flex gap-2">
          <div class="">
            <figure class="" v-if="member.parent.avatar">
              <img
                class="rounded-lg"
                :src="member.parent.avatar.url"
                alt=""
                width="48"
                height="48"
              />
            </figure>
            <AccountGroup v-else :size="48" />
          </div>
          <div class="" dir="auto">
            <router-link
              :to="{
                name: RouteName.GROUP,
                params: {
                  preferredUsername: usernameWithDomain(member.parent),
                },
              }"
            >
              <h2 class="mt-0">{{ member.parent.name }}</h2>
              <div class="flex flex-col items-start">
                <span class="text-sm">{{
                  `@${usernameWithDomain(member.parent)}`
                }}</span>
                <tag
                  variant="info"
                  v-if="member.role === MemberRole.ADMINISTRATOR"
                  >{{ t("Administrator") }}</tag
                >
                <tag
                  variant="info"
                  v-else-if="member.role === MemberRole.MODERATOR"
                  >{{ t("Moderator") }}</tag
                >
              </div>
            </router-link>
          </div>
        </div>
        <div
          class="mt-3 prose dark:prose-invert lg:prose-xl line-clamp-2"
          v-if="member.parent.summary"
          v-html="htmlToText(member.parent.summary)"
        />
      </div>
      <div>
        <o-dropdown aria-role="list" position="bottom-left">
          <template #trigger>
            <DotsHorizontal class="cursor-pointer" />
          </template>

          <o-dropdown-item
            class="inline-flex gap-1"
            aria-role="listitem"
            @click="emit('leave')"
          >
            <ExitToApp />
            {{ t("Leave") }}
          </o-dropdown-item>
        </o-dropdown>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { displayNameAndUsername, usernameWithDomain } from "@/types/actor";
import { IMember } from "@/types/actor/member.model";
import { MemberRole } from "@/types/enums";
import RouteName from "../../router/name";
import ExitToApp from "vue-material-design-icons/ExitToApp.vue";
import DotsHorizontal from "vue-material-design-icons/DotsHorizontal.vue";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Tag from "@/components/TagElement.vue";
import { htmlToText } from "@/utils/html";
import { useI18n } from "vue-i18n";

defineProps<{
  member: IMember;
}>();

const emit = defineEmits(["leave"]);

const { t } = useI18n({ useScope: "global" });
</script>
