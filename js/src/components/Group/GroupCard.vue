<template>
  <router-link
    :to="{
      name: RouteName.GROUP,
      params: { preferredUsername: usernameWithDomain(group) },
    }"
    class="card flex flex-col max-w-md bg-white dark:bg-mbz-purple dark:text-white rounded-lg shadow-lg"
  >
    <figure class="rounded-t-lg flex justify-center h-1/4">
      <lazy-image-wrapper :picture="group.banner" :rounded="true" />
    </figure>
    <div class="py-2 pl-2">
      <div class="flex gap-1 mb-2">
        <div class="">
          <figure class="" v-if="group.avatar">
            <img class="rounded-xl" :src="group.avatar.url" alt="" />
          </figure>
          <AccountGroup v-else :size="48" />
        </div>
        <div class="">
          <h3 class="text-2xl" dir="auto">
            {{ displayName(group) }}
          </h3>
          <span class="is-6 has-text-grey-dark group-federated-username">
            {{ `@${usernameWithDomain(group)}` }}
          </span>
        </div>
      </div>
      <div class="mb-2 line-clamp-3" dir="auto" v-html="group.summary" />
      <div>
        <inline-address
          v-if="group.physicalAddress && addressFullName(group.physicalAddress)"
          :physicalAddress="group.physicalAddress"
        />
        <p class="flex">
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

defineProps<{
  group: IGroup;
}>();

const { t } = useI18n({ useScope: "global" });
</script>
