<template>
  <LinkOrRouterLink
    :to="to"
    :isInternal="isInternal"
    class="mbz-card shrink-0 dark:bg-mbz-purple dark:text-white rounded-lg shadow-lg flex items-center flex-col"
    :class="{
      'sm:flex-row': mode === 'row',
      'sm:max-w-xs sm:w-[18rem] shrink-0 flex flex-col': mode === 'column',
    }"
  >
    <div class="flex-none p-2 md:p-4">
      <figure class="" v-if="group.avatar">
        <img
          class="rounded-full"
          :src="group.avatar.url"
          alt=""
          height="128"
          width="128"
        />
      </figure>
      <AccountGroup v-else :size="128" />
    </div>
    <div
      class="py-2 px-2 md:px-4 flex flex-col h-full justify-between w-full"
      :class="{ 'sm:flex-1': mode === 'row' }"
    >
      <div class="flex gap-1 mb-2">
        <div class="overflow-hidden flex-auto">
          <h3
            class="text-2xl leading-5 line-clamp-3 font-bold text-violet-3 dark:text-white"
            dir="auto"
          >
            {{ displayName(group) }}
          </h3>
          <span class="block truncate">
            {{ `@${usernameWithDomain(group)}` }}
          </span>
        </div>
      </div>
      <div
        class="mb-2 line-clamp-3"
        dir="auto"
        v-html="saneSummary"
        v-if="showSummary"
      />
      <div>
        <inline-address
          v-if="group.physicalAddress && addressFullName(group.physicalAddress)"
          :physicalAddress="group.physicalAddress"
        />
        <p
          class="flex gap-1"
          v-if="group?.members?.total && group?.followers?.total"
        >
          <Account />
          {{
            t(
              "{count} members or followers",
              {
                count: group.members.total + group.followers.total,
              },
              group.members.total + group.followers.total
            )
          }}
        </p>
        <p
          class="flex gap-1"
          v-else-if="group?.membersCount || group?.followersCount"
        >
          <Account />
          {{
            t(
              "{count} members or followers",
              {
                count: (group.membersCount ?? 0) + (group.followersCount ?? 0),
              },
              (group.membersCount ?? 0) + (group.followersCount ?? 0)
            )
          }}
        </p>
      </div>
    </div>
  </LinkOrRouterLink>
</template>

<script lang="ts" setup>
import { displayName, IGroup, usernameWithDomain } from "@/types/actor";
import RouteName from "../../router/name";
import InlineAddress from "@/components/Address/InlineAddress.vue";
import { addressFullName } from "@/types/address.model";
import { useI18n } from "vue-i18n";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import Account from "vue-material-design-icons/Account.vue";
import { htmlToText } from "@/utils/html";
import { computed } from "vue";
import LinkOrRouterLink from "../core/LinkOrRouterLink.vue";

const props = withDefaults(
  defineProps<{
    group: IGroup;
    showSummary?: boolean;
    isRemoteGroup?: boolean;
    isLoggedIn?: boolean;
    mode?: "row" | "column";
  }>(),
  { showSummary: true, isRemoteGroup: false, isLoggedIn: true, mode: "column" }
);

const { t } = useI18n({ useScope: "global" });

const saneSummary = computed(() => htmlToText(props.group.summary ?? ""));

const isInternal = computed(() => {
  return props.isRemoteGroup && props.isLoggedIn === false;
});

const to = computed(() => {
  if (props.isRemoteGroup) {
    if (props.isLoggedIn === false) {
      return props.group.url;
    }
    return {
      name: RouteName.INTERACT,
      query: { uri: encodeURI(props.group.url) },
    };
  }
  return {
    name: RouteName.GROUP,
    params: { preferredUsername: usernameWithDomain(props.group) },
  };
});
</script>
