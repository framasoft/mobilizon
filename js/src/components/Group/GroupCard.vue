<template>
  <router-link
    :to="{
      name: RouteName.GROUP,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
    class="card flex flex-col shrink-0 w-[18rem] bg-white dark:bg-mbz-purple dark:text-white rounded-lg shadow-lg"
  >
    <figure class="rounded-t-lg flex justify-center h-40">
      <lazy-image-wrapper :picture="group.banner" :rounded="true" />
    </figure>
    <div class="py-2 pl-2">
      <div class="flex gap-1 mb-2">
        <div class="">
          <figure class="" v-if="group.avatar">
            <img
              class="rounded-xl"
              :src="group.avatar.url"
              alt=""
              height="64"
              width="64"
            />
          </figure>
          <AccountGroup v-else :size="64" />
        </div>
        <div class="px-1 overflow-hidden">
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
        <p class="flex gap-1">
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
      </div>
    </div>
  </router-link>
</template>

<script lang="ts" setup>
import { displayName, IGroup, usernameWithDomain } from "@/types/actor";
import LazyImageWrapper from "@/components/Image/LazyImageWrapper.vue";
import RouteName from "../../router/name";
import InlineAddress from "@/components/Address/InlineAddress.vue";
import { addressFullName } from "@/types/address.model";
import { useI18n } from "vue-i18n";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import Account from "vue-material-design-icons/Account.vue";
import { htmlToText } from "@/utils/html";
import { computed } from "vue";

const props = withDefaults(
  defineProps<{
    group: IGroup;
    showSummary: boolean;
  }>(),
  { showSummary: true }
);

const { t } = useI18n({ useScope: "global" });

const saneSummary = computed(() => htmlToText(props.group.summary));
</script>
