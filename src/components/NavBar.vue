<template>
  <nav
    class="bg-white border-gray-200 px-2 sm:px-4 py-2.5 dark:bg-zinc-900"
    id="navbar"
  >
    <div class="container mx-auto flex flex-wrap items-center gap-2 sm:gap-4">
      <router-link
        :to="{ name: RouteName.HOME }"
        class="flex items-center"
        :class="{ 'flex-1': !currentActor?.id }"
      >
        <MobilizonLogo class="w-40" />
      </router-link>
      <div
        class="flex items-center md:order-2 ml-auto gap-2"
        v-if="currentActor?.id"
      >
        <router-link
          :to="{ name: RouteName.CONVERSATION_LIST }"
          class="flex sm:mr-3 text-sm md:mr-0 relative"
          id="conversations-menu-button"
          aria-expanded="false"
        >
          <span class="sr-only">{{ t("Open conversations") }}</span>
          <Inbox :size="32" />
          <span
            v-show="unreadConversationsCount > 0"
            class="absolute bottom-0.5 -left-2 bg-primary rounded-full inline-block h-3 w-3 mx-2"
          >
          </span>
        </router-link>
        <o-dropdown position="bottom-right">
          <template #trigger>
            <button
              type="button"
              class="flex sm:mr-3 text-sm rounded-full md:mr-0 focus:ring-4 focus:ring-gray-300 dark:focus:ring-gray-600"
              id="user-menu-button"
              aria-expanded="false"
            >
              <span class="sr-only">{{ t("Open user menu") }}</span>
              <figure class="h-8 w-8" v-if="currentActor?.avatar">
                <img
                  class="rounded-full w-full h-full object-cover"
                  alt=""
                  :src="currentActor?.avatar.url"
                  width="32"
                  height="32"
                  loading="lazy"
                />
              </figure>
              <AccountCircle v-else :size="32" />
            </button>
          </template>

          <!-- Dropdown menu -->
          <div
            class="z-50 text-base list-none bg-white rounded divide-y divide-gray-100 dark:bg-zinc-700 dark:divide-gray-600 max-w-xs"
            position="bottom-left"
          >
            <o-dropdown-item aria-role="listitem">
              <div class="px-4">
                <span class="block text-sm text-zinc-900 dark:text-white">{{
                  displayName(currentActor)
                }}</span>
                <span
                  class="block text-sm font-medium text-zinc-500 truncate dark:text-zinc-400"
                  v-if="currentUser?.role === ICurrentUserRole.ADMINISTRATOR"
                  >{{ t("Administrator") }}</span
                >
                <span
                  class="block text-sm font-medium text-zinc-500 truncate dark:text-zinc-400"
                  v-if="currentUser?.role === ICurrentUserRole.MODERATOR"
                  >{{ t("Moderator") }}</span
                >
              </div>
            </o-dropdown-item>
            <o-dropdown-item
              v-for="identity in identities"
              :active="identity.id === currentActor.id"
              :key="identity.id"
              tabindex="0"
              @click="
                setIdentity({
                  preferredUsername: identity.preferredUsername,
                })
              "
              @keyup.enter="
                setIdentity({
                  preferredUsername: identity.preferredUsername,
                })
              "
            >
              <div class="flex gap-1 items-center w-full">
                <div class="flex-none">
                  <figure class="h-8 w-8" v-if="identity.avatar">
                    <img
                      class="rounded-full object-cover h-full"
                      loading="lazy"
                      :src="identity.avatar.url"
                      alt=""
                      height="32"
                      width="32"
                    />
                  </figure>
                  <AccountCircle v-else :size="32" />
                </div>

                <div
                  class="text-base text-zinc-700 dark:text-zinc-100 flex flex-col flex-auto overflow-hidden items-start w-full"
                >
                  <p class="truncate w-full">{{ displayName(identity) }}</p>
                  <p class="truncate text-sm w-full" v-if="identity.name">
                    @{{ identity.preferredUsername }}
                  </p>
                </div>
              </div>
            </o-dropdown-item>
            <o-dropdown-item
              aria-role="listitem"
              tag="router-link"
              :to="{ name: RouteName.SETTINGS }"
            >
              <span
                class="block py-2 px-4 text-sm text-zinc-700 dark:text-zinc-200 dark:hover:text-white"
                >{{ t("My account") }}</span
              >
            </o-dropdown-item>
            <o-dropdown-item
              aria-role="listitem"
              v-if="currentUser?.role === ICurrentUserRole.ADMINISTRATOR"
              tag="router-link"
              :to="{ name: RouteName.ADMIN_DASHBOARD }"
            >
              <span
                class="block py-2 px-4 text-sm text-zinc-700 dark:text-zinc-200 dark:hover:text-white"
                >{{ t("Administration") }}</span
              >
            </o-dropdown-item>
            <o-dropdown-item
              aria-role="listitem"
              @click="performLogout"
              @keyup.enter="performLogout"
            >
              <span
                class="block py-2 px-4 text-sm text-zinc-700 dark:text-zinc-200 dark:hover:text-white"
                >{{ t("Log out") }}</span
              >
            </o-dropdown-item>
          </div>
        </o-dropdown>
      </div>
      <button
        @click="showMobileMenu = !showMobileMenu"
        type="button"
        class="inline-flex items-center p-2 ml-1 text-sm text-zinc-500 rounded-lg md:hidden hover:bg-zinc-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-zinc-400 dark:hover:bg-zinc-700 dark:focus:ring-gray-600"
        aria-controls="mobile-menu-2"
        aria-expanded="false"
      >
        <span class="sr-only">{{ t("Open main menu") }}</span>
        <svg
          class="w-6 h-6"
          aria-hidden="true"
          fill="currentColor"
          viewBox="0 0 20 20"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fill-rule="evenodd"
            d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z"
            clip-rule="evenodd"
          ></path>
        </svg>
      </button>
      <div
        class="justify-between items-center w-full md:flex md:w-auto md:order-1"
        id="mobile-menu-2"
        :class="{ hidden: !showMobileMenu }"
      >
        <ul
          class="flex flex-col md:flex-row md:space-x-8 mt-2 md:mt-0 md:font-lightbold"
        >
          <li class="m-auto">
            <router-link
              :to="{
                ...$route,
                name: RouteName.SEARCH,
                query: { ...$route.query, contentType: 'EVENTS' },
              }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("Events") }}</router-link
            >
          </li>
          <li class="m-auto" v-if="islongEvents">
            <router-link
              :to="{
                ...$route,
                name: RouteName.SEARCH,
                query: { ...$route.query, contentType: 'LONGEVENTS' },
              }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("Activities") }}</router-link
            >
          </li>
          <li class="m-auto">
            <router-link
              :to="{
                ...$route,
                name: RouteName.SEARCH,
                query: { ...$route.query, contentType: 'GROUPS' },
              }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("Groups") }}</router-link
            >
          </li>
          <li class="m-auto">
            <router-link
              :to="{ name: RouteName.EVENT_CALENDAR }"
              class="block relative py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("Calendar")
              }}<span class="absolute right-0 text-xs"
                ><br />(beta)</span
              ></router-link
            >
          </li>
          <li class="m-auto" v-if="currentActor?.id">
            <router-link
              :to="{ name: RouteName.MY_EVENTS }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("My events") }}</router-link
            >
          </li>
          <li class="m-auto" v-if="currentActor?.id">
            <router-link
              :to="{ name: RouteName.MY_GROUPS }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("My groups") }}</router-link
            >
          </li>
          <li class="m-auto" v-if="!currentActor?.id">
            <router-link
              :to="{ name: RouteName.LOGIN }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("Login") }}</router-link
            >
          </li>
          <li class="m-auto" v-if="!currentActor?.id && canRegister">
            <router-link
              :to="{ name: RouteName.REGISTER }"
              class="block py-2 pr-4 pl-3 text-zinc-700 border-b border-gray-100 hover:bg-zinc-50 md:hover:bg-transparent md:border-0 md:hover:text-mbz-purple-700 md:p-0 dark:text-zinc-400 md:dark:hover:text-white dark:hover:bg-zinc-700 dark:hover:text-white md:dark:hover:bg-transparent dark:border-gray-700"
              >{{ t("Register") }}</router-link
            >
          </li>
        </ul>
      </div>
    </div>
  </nav>
</template>

<script lang="ts" setup>
import MobilizonLogo from "@/components/MobilizonLogo.vue";
import { ICurrentUserRole } from "@/types/enums";
import { logout } from "../utils/auth";
import { displayName } from "../types/actor";
import RouteName from "../router/name";
import { computed, onMounted, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import Inbox from "vue-material-design-icons/Inbox.vue";
import { useCurrentUserClient } from "@/composition/apollo/user";
import {
  useCurrentActorClient,
  useCurrentUserIdentities,
} from "@/composition/apollo/actor";
import { useLazyQuery, useMutation } from "@vue/apollo-composable";
import { UPDATE_DEFAULT_ACTOR } from "@/graphql/actor";
import { changeIdentity } from "@/utils/identity";
import {
  useRegistrationConfig,
  useIsLongEvents,
} from "@/composition/apollo/config";
import { useOruga } from "@oruga-ui/oruga-next";
import {
  UNREAD_ACTOR_CONVERSATIONS,
  UNREAD_ACTOR_CONVERSATIONS_SUBSCRIPTION,
} from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";

const { islongEvents } = useIsLongEvents();

const { currentUser } = useCurrentUserClient();
const { currentActor } = useCurrentActorClient();

const router = useRouter();
const route = useRoute();

const { identities } = useCurrentUserIdentities();
const { registrationsOpen, registrationsAllowlist, databaseLogin } =
  useRegistrationConfig();

const canRegister = computed(() => {
  return (
    ((registrationsOpen.value || registrationsAllowlist.value) &&
      databaseLogin.value) ??
    false
  );
});

const { t } = useI18n({ useScope: "global" });

const unreadConversationsCount = computed(
  () =>
    unreadActorConversationsResult.value?.loggedUser.defaultActor
      ?.unreadConversationsCount ?? 0
);

const {
  result: unreadActorConversationsResult,
  load: loadUnreadConversations,
  subscribeToMore,
} = useLazyQuery<{
  loggedUser: Pick<ICurrentUser, "id" | "defaultActor">;
}>(UNREAD_ACTOR_CONVERSATIONS);

watch(currentActor, async (currentActorValue, previousActorValue) => {
  if (
    currentActorValue?.id &&
    currentActorValue.preferredUsername !==
      previousActorValue?.preferredUsername
  ) {
    await loadUnreadConversations();

    subscribeToMore<
      { personId: string },
      { personUnreadConversationsCount: number }
    >({
      document: UNREAD_ACTOR_CONVERSATIONS_SUBSCRIPTION,
      variables: {
        personId: currentActor.value?.id as string,
      },
      updateQuery: (previousResult, { subscriptionData }) => {
        console.debug(
          "Updating actor unread conversations count query after subscribe to more update",
          subscriptionData?.data?.personUnreadConversationsCount
        );
        return {
          ...previousResult,
          loggedUser: {
            id: previousResult.loggedUser.id,
            defaultActor: {
              ...previousResult.loggedUser.defaultActor,
              unreadConversationsCount:
                subscriptionData?.data?.personUnreadConversationsCount ??
                previousResult.loggedUser.defaultActor
                  ?.unreadConversationsCount,
            } as IPerson, // no idea why,
          },
        };
      },
    });
  }
});

onMounted(() => {});

watch(identities, () => {
  // If we don't have any identities, the user has validated their account,
  // is logging for the first time but didn't create an identity somehow
  if (identities.value && identities.value.length === 0) {
    console.warn(
      "We have no identities listed for current user",
      identities.value
    );
    console.info("Pushing route to REGISTER_PROFILE");
    router.push({
      name: RouteName.REGISTER_PROFILE,
      params: {
        email: currentUser.value?.email,
        userAlreadyActivated: "true",
      },
    });
  }
});

const { onDone, mutate: setIdentity } = useMutation<{
  changeDefaultActor: { id: string; defaultActor: { id: string } };
}>(UPDATE_DEFAULT_ACTOR);

onDone(({ data }) => {
  const identity = identities.value?.find(
    ({ id }) => id === data?.changeDefaultActor?.defaultActor?.id
  );
  if (!identity) return;
  changeIdentity(identity);
});

const showMobileMenu = ref(false);

const { notification } = useOruga();

const performLogout = async () => {
  console.debug("Logging out client...");
  await logout();
  notification.open({
    message: t("You have been logged-out"),
    variant: "success",
    position: "bottom-right",
    duration: 5000,
  });

  if (route.meta["requiredAuth"] === true) {
    return router.push({ name: RouteName.HOME });
  }
};
</script>
