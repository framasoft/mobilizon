<template>
  <div v-if="instance">
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: $t('Admin') },
        { name: RouteName.INSTANCES, text: $t('Instances') },
        { text: instance.domain },
      ]"
    />
    <h1 class="text-2xl">{{ instance.domain }}</h1>
    <div
      class="grid md:grid-cols-2 xl:grid-cols-4 gap-2 content-center text-center mt-2"
    >
      <div class="bg-zinc-50 dark:bg-mbz-purple-500 rounded-xl p-8">
        <router-link
          :to="{
            name: RouteName.PROFILES,
            query: { domain: instance.domain },
          }"
        >
          <span class="mb-4 text-xl font-semibold block">{{
            instance.personCount
          }}</span>
          <span class="text-sm block">{{ $t("Profiles") }}</span>
        </router-link>
      </div>
      <div class="bg-gray-50 dark:bg-mbz-purple-500 rounded-xl p-8">
        <router-link
          :to="{
            name: RouteName.ADMIN_GROUPS,
            query: { domain: instance.domain },
          }"
        >
          <span class="mb-4 text-xl font-semibold block">{{
            instance.groupCount
          }}</span>
          <span class="text-sm block">{{ $t("Groups") }}</span>
        </router-link>
      </div>
      <div class="bg-zinc-50 dark:bg-mbz-purple-500 rounded-xl p-8">
        <span class="mb-4 text-xl font-semibold block">{{
          instance.followingsCount
        }}</span>
        <span class="text-sm block">{{ $t("Followings") }}</span>
      </div>
      <div class="bg-zinc-50 dark:bg-mbz-purple-500 rounded-xl p-8">
        <span class="mb-4 text-xl font-semibold block">{{
          instance.followersCount
        }}</span>
        <span class="text-sm block">{{ $t("Followers") }}</span>
      </div>
      <div class="bg-zinc-50 dark:bg-mbz-purple-500 rounded-xl p-8">
        <router-link
          :to="{ name: RouteName.REPORTS, query: { domain: instance.domain } }"
        >
          <span class="mb-4 text-xl font-semibold block">{{
            instance.reportsCount
          }}</span>
          <span class="text-sm block">{{ $t("Reports") }}</span>
        </router-link>
      </div>
      <div class="bg-zinc-50 dark:bg-mbz-purple-500 rounded-xl p-8">
        <span class="mb-4 font-semibold block">{{
          formatBytes(instance.mediaSize)
        }}</span>
        <span class="text-sm block">{{ $t("Uploaded media size") }}</span>
      </div>
    </div>
    <div class="mt-3 grid xl:grid-cols-2 gap-4">
      <div
        class="border bg-white dark:bg-mbz-purple-500 dark:border-mbz-purple-700 p-6 shadow-md rounded-md"
        v-if="instance.hasRelay"
      >
        <button
          @click="
            removeInstanceFollow({
              address: instance?.relayAddress,
            })
          "
          v-if="instance.followedStatus == InstanceFollowStatus.APPROVED"
          class="bg-primary hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 focus:ring-offset-gray-50 text-white hover:text-white font-semibold h-12 px-6 rounded-lg w-full flex items-center justify-center sm:w-auto"
        >
          {{ $t("Stop following instance") }}
        </button>
        <button
          @click="
            removeInstanceFollow({
              address: instance?.relayAddress,
            })
          "
          v-else-if="instance.followedStatus == InstanceFollowStatus.PENDING"
          class="bg-primary hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 focus:ring-offset-gray-50 text-white hover:text-white font-semibold h-12 px-6 rounded-lg w-full flex items-center justify-center sm:w-auto"
        >
          {{ $t("Cancel follow request") }}
        </button>
        <button
          @click="followInstance"
          v-else
          class="bg-primary hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 focus:ring-offset-gray-50 text-white hover:text-white font-semibold h-12 px-6 rounded-lg w-full flex items-center justify-center sm:w-auto"
        >
          {{ $t("Follow instance") }}
        </button>
      </div>
      <div v-else class="md:h-48 py-16 text-center opacity-50">
        {{ $t("Only Mobilizon instances can be followed") }}
      </div>
      <div
        class="border bg-white dark:bg-mbz-purple-500 dark:border-mbz-purple-700 p-6 shadow-md rounded-md flex flex-col gap-2"
      >
        <button
          @click="
            acceptInstance({
              address: instance?.relayAddress,
            })
          "
          v-if="instance.followerStatus == InstanceFollowStatus.PENDING"
          class="bg-green-700 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 focus:ring-offset-gray-50 text-white hover:text-white font-semibold h-12 px-6 rounded-lg w-full flex items-center justify-center sm:w-auto"
        >
          {{ $t("Accept follow") }}
        </button>
        <button
          @click="
            rejectInstance({
              address: instance?.relayAddress,
            })
          "
          v-if="instance.followerStatus != InstanceFollowStatus.NONE"
          class="bg-red-700 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 focus:ring-offset-gray-50 text-white hover:text-white font-semibold h-12 px-6 rounded-lg w-full flex items-center justify-center sm:w-auto"
        >
          {{ $t("Reject follow") }}
        </button>
        <p v-if="instance.followerStatus == InstanceFollowStatus.NONE">
          {{ $t("This instance doesn't follow yours.") }}
        </p>
      </div>
    </div>
  </div>
</template>
<script lang="ts" setup>
import {
  ACCEPT_RELAY,
  ADD_INSTANCE,
  INSTANCE,
  REJECT_RELAY,
  REMOVE_RELAY,
} from "@/graphql/admin";
import { formatBytes } from "@/utils/datetime";
import RouteName from "@/router/name";
import { IInstance } from "@/types/instance.model";
import { ApolloCache, gql, Reference } from "@apollo/client/core";
import { InstanceFollowStatus } from "@/types/enums";
import { useMutation, useQuery } from "@vue/apollo-composable";
import { computed, inject } from "vue";
import { Notifier } from "@/plugins/notifier";

const props = defineProps<{ domain: string }>();

const { result: instanceResult } = useQuery<{ instance: IInstance }>(
  INSTANCE,
  () => ({ domain: props.domain })
);

const instance = computed(() => instanceResult.value?.instance);

const notifier = inject<Notifier>("notifier");

const { mutate: acceptInstance, onError: onAcceptInstanceError } = useMutation(
  ACCEPT_RELAY,
  () => ({
    update(cache: ApolloCache<any>) {
      cache.writeFragment({
        id: cache.identify(instance.value as unknown as Reference),
        fragment: gql`
          fragment InstanceFollowerStatus on Instance {
            followerStatus
          }
        `,
        data: {
          followerStatus: InstanceFollowStatus.APPROVED,
        },
      });
    },
  })
);

onAcceptInstanceError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

/**
 * Reject instance follow
 */
const { mutate: rejectInstance, onError: onRejectInstanceError } = useMutation(
  REJECT_RELAY,
  () => ({
    update(cache: ApolloCache<any>) {
      cache.writeFragment({
        id: cache.identify(instance as unknown as Reference),
        fragment: gql`
          fragment InstanceFollowerStatus on Instance {
            followerStatus
          }
        `,
        data: {
          followerStatus: InstanceFollowStatus.NONE,
        },
      });
    },
  })
);

onRejectInstanceError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const { mutate: followInstanceMutation, onError: onFollowInstanceError } =
  useMutation<{ addInstance: IInstance }>(ADD_INSTANCE);

onFollowInstanceError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const followInstance = async (e: Event): Promise<void> => {
  e.preventDefault();
  followInstanceMutation({ domain: props.domain });
};

/**
 * Stop following instance
 */
const { mutate: removeInstanceFollow, onError: onRemoveInstanceFollowError } =
  useMutation(REMOVE_RELAY, () => ({
    update(cache: ApolloCache<any>) {
      cache.writeFragment({
        id: cache.identify(instance.value as unknown as Reference),
        fragment: gql`
          fragment InstanceFollowedStatus on Instance {
            followedStatus
          }
        `,
        data: {
          followedStatus: InstanceFollowStatus.NONE,
        },
      });
    },
  }));

onRemoveInstanceFollowError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});
</script>
