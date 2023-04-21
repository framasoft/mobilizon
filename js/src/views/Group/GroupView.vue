<template>
  <div class="container mx-auto is-widescreen">
    <div class="header flex flex-col">
      <breadcrumbs-nav
        v-if="group"
        :links="[
          { name: RouteName.MY_GROUPS, text: t('My groups') },
          {
            name: RouteName.GROUP,
            params: { preferredUsername: usernameWithDomain(group) },
            text: displayName(group),
          },
        ]"
      />
      <!-- <o-loading v-model:active="$apollo.loading"></o-loading> -->
      <header class="block-container presentation" v-if="group">
        <div class="banner-container">
          <lazy-image-wrapper :picture="group.banner" />
        </div>
        <div class="header flex flex-col">
          <div class="flex self-center h-0 mt-4 items-end">
            <figure class="" v-if="group.avatar">
              <img
                class="rounded-full border h-32 w-32"
                :src="group.avatar.url"
                alt=""
                width="128"
                height="128"
              />
            </figure>
            <AccountGroup v-else :size="128" />
          </div>
          <div class="title-container flex flex-1 flex-col text-center">
            <h1 class="m-0" v-if="group.name">
              {{ group.name }}
            </h1>
            <!-- <o-skeleton v-else :animated="true" /> -->
            <span dir="ltr" class="" v-if="group.preferredUsername"
              >@{{ usernameWithDomain(group) }}</span
            >
            <!-- <o-skeleton v-else :animated="true" /> -->
            <br />
          </div>
          <div class="flex flex-wrap justify-center flex-col md:flex-row">
            <div
              class="flex flex-col items-center flex-1 m-0"
              v-if="isCurrentActorAGroupMember && !previewPublic"
            >
              <div class="flex gap-1">
                <figure
                  :title="
                    t(`{'@'}{username} ({role})`, {
                      username: usernameWithDomain(member.actor),
                      role: member.role,
                    })
                  "
                  v-for="member in members"
                  :key="member.actor.id"
                >
                  <img
                    class="rounded-full"
                    :src="member.actor.avatar.url"
                    v-if="member.actor.avatar"
                    alt=""
                    width="32"
                    height="32"
                  />
                  <AccountCircle v-else :size="32" />
                </figure>
              </div>
              <p>
                {{
                  t(
                    "{count} members",
                    {
                      count: group.members?.total,
                    },
                    group.members?.total
                  )
                }}
                <router-link
                  v-if="isCurrentActorAGroupAdmin"
                  :to="{
                    name: RouteName.GROUP_MEMBERS_SETTINGS,
                    params: { preferredUsername: usernameWithDomain(group) },
                  }"
                  >{{ t("Add / Remove…") }}</router-link
                >
              </p>
            </div>
            <div class="flex flex-wrap gap-3 justify-center">
              <o-button
                outlined
                icon-left="timeline-text"
                v-if="isCurrentActorAGroupMember && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.TIMELINE,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                >{{ t("Activity") }}</o-button
              >
              <o-button
                outlined
                icon-left="cog"
                v-if="isCurrentActorAGroupAdmin && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.GROUP_PUBLIC_SETTINGS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                >{{ t("Group settings") }}</o-button
              >
              <o-dropdown
                aria-role="list"
                v-if="showJoinButton && showFollowButton"
              >
                <template #trigger>
                  <o-button
                    variant="primary"
                    icon-left="rss"
                    icon-right="menu-down"
                  >
                    {{ t("Follow") }}
                  </o-button>
                </template>

                <o-dropdown-item
                  aria-role="listitem"
                  class="p-0"
                  custom
                  :focusable="false"
                  :disabled="
                    isCurrentActorPendingFollow &&
                    currentActor?.id !== undefined
                  "
                >
                  <button
                    class="flex gap-1 text-start py-4 px-2 w-full"
                    @click="followGroup"
                  >
                    <RSS />
                    <div class="pl-2">
                      <h3 class="font-medium text-lg">{{ t("Follow") }}</h3>
                      <p class="whitespace-normal md:whitespace-nowrap text-sm">
                        {{ t("Get informed of the upcoming public events") }}
                      </p>
                      <p
                        v-if="
                          doesGroupManuallyApprovesFollowers &&
                          !isCurrentActorPendingFollow
                        "
                        class="whitespace-normal md:whitespace-nowrap text-sm italic"
                      >
                        {{
                          t(
                            "Follow requests will be approved by a group moderator"
                          )
                        }}
                      </p>
                      <p
                        v-if="isCurrentActorPendingFollow && currentActor?.id"
                        class="whitespace-normal md:whitespace-nowrap text-sm italic"
                      >
                        {{ t("Follow request pending approval") }}
                      </p>
                    </div>
                  </button>
                </o-dropdown-item>

                <o-dropdown-item
                  aria-role="listitem"
                  class="p-0 border-t border-solid"
                  custom
                  :focusable="false"
                  :disabled="
                    isGroupInviteOnly || isCurrentActorAPendingGroupMember
                  "
                >
                  <button
                    class="flex gap-1 text-start py-4 px-2 w-full"
                    @click="joinGroup"
                  >
                    <AccountMultiplePlus />
                    <div class="pl-2">
                      <h3 class="font-medium text-lg">{{ t("Join") }}</h3>
                      <div v-if="showJoinButton">
                        <p
                          class="whitespace-normal md:whitespace-nowrap text-sm"
                        >
                          {{
                            t(
                              "Become part of the community and start organizing events"
                            )
                          }}
                        </p>
                        <p
                          v-if="isGroupInviteOnly"
                          class="whitespace-normal md:whitespace-nowrap text-sm italic"
                        >
                          {{ t("This group is invite-only") }}
                        </p>
                        <p
                          v-if="
                            areGroupMembershipsModerated &&
                            !isCurrentActorAPendingGroupMember
                          "
                          class="whitespace-normal md:whitespace-nowrap text-sm italic"
                        >
                          {{
                            t(
                              "Membership requests will be approved by a group moderator"
                            )
                          }}
                        </p>
                        <p
                          v-if="isCurrentActorAPendingGroupMember"
                          class="whitespace-normal md:whitespace-nowrap text-sm italic"
                        >
                          {{ t("Your membership is pending approval") }}
                        </p>
                      </div>
                    </div>
                  </button>
                </o-dropdown-item>
              </o-dropdown>
              <o-button
                outlined
                v-if="isCurrentActorAPendingGroupMember"
                @click="leaveGroup"
                @keyup.enter="leaveGroup"
                variant="primary"
                >{{ t("Cancel membership request") }}</o-button
              >
              <o-button
                outlined
                v-if="isCurrentActorPendingFollow && currentActor?.id"
                @click="unFollowGroup"
                @keyup.enter="unFollowGroup"
                variant="primary"
                >{{ t("Cancel follow request") }}</o-button
              ><o-button
                v-if="
                  isCurrentActorFollowing && !previewPublic && currentActor?.id
                "
                variant="primary"
                @click="unFollowGroup"
                >{{ t("Unfollow") }}</o-button
              >
              <o-button
                v-if="isCurrentActorFollowing"
                @click="toggleFollowNotify"
                @keyup.enter="toggleFollowNotify"
                class="notification-button p-1.5"
                outlined
                :icon-left="
                  isCurrentActorFollowingNotify
                    ? 'bell-outline'
                    : 'bell-off-outline'
                "
              >
                <span class="sr-only">{{
                  isCurrentActorFollowingNotify
                    ? t("Activate notifications")
                    : t("Deactivate notifications")
                }}</span>
              </o-button>
              <o-button
                outlined
                icon-left="share"
                @click="triggerShare()"
                @keyup.enter="triggerShare()"
                v-if="!isCurrentActorAGroupMember || previewPublic"
              >
                {{ t("Share") }}
              </o-button>
              <o-dropdown aria-role="list">
                <template #trigger>
                  <o-button
                    outlined
                    icon-left="dots-horizontal"
                    :aria-label="t('Other actions')"
                  ></o-button>
                </template>
                <o-dropdown-item
                  aria-role="menuitem"
                  v-if="isCurrentActorAGroupMember || previewPublic"
                >
                  <o-switch v-model="previewPublic">{{
                    t("Public preview")
                  }}</o-switch>
                </o-dropdown-item>
                <o-dropdown-item
                  v-if="!previewPublic && isCurrentActorAGroupMember"
                  aria-role="menuitem"
                  @click="triggerShare()"
                  @keyup.enter="triggerShare()"
                >
                  <span class="inline-flex gap-1">
                    <Share />
                    {{ t("Share") }}
                  </span>
                </o-dropdown-item>
                <hr
                  role="presentation"
                  class="dropdown-divider"
                  v-if="isCurrentActorAGroupMember"
                />
                <o-dropdown-item has-link aria-role="menuitem">
                  <a
                    :href="`@${preferredUsername}/feed/atom`"
                    :title="t('Atom feed for events and posts')"
                    class="inline-flex gap-1"
                  >
                    <RSS />
                    {{ t("RSS/Atom Feed") }}
                  </a>
                </o-dropdown-item>
                <o-dropdown-item has-link aria-role="menuitem">
                  <a
                    :href="`@${preferredUsername}/feed/ics`"
                    :title="t('ICS feed for events')"
                    class="inline-flex gap-1"
                  >
                    <CalendarSync />
                    {{ t("ICS/WebCal Feed") }}
                  </a>
                </o-dropdown-item>
                <hr role="presentation" class="dropdown-divider" />
                <o-dropdown-item
                  v-if="ableToReport"
                  aria-role="menuitem"
                  @click="isReportModalActive = true"
                  @keyup.enter="isReportModalActive = true"
                >
                  <span class="inline-flex gap-1">
                    <Flag />
                    {{ t("Report") }}
                  </span>
                </o-dropdown-item>
                <o-dropdown-item
                  aria-role="menuitem"
                  v-if="isCurrentActorAGroupMember && !previewPublic"
                  @click="openLeaveGroupModal"
                  @keyup.enter="openLeaveGroupModal"
                >
                  <span class="inline-flex gap-1">
                    <ExitToApp />
                    {{ t("Leave") }}
                  </span>
                </o-dropdown-item>
              </o-dropdown>
            </div>
          </div>
          <InvitationsList
            v-if="
              isCurrentActorAnInvitedGroupMember && groupMember !== undefined
            "
            :invitations="[groupMember]"
          />
          <o-notification
            v-if="isCurrentActorARejectedGroupMember"
            variant="danger"
          >
            {{ t("You have been removed from this group's members.") }}
          </o-notification>
          <o-notification
            v-if="
              isCurrentActorAGroupMember &&
              isCurrentActorARecentMember &&
              isCurrentActorOnADifferentDomainThanGroup
            "
            variant="info"
          >
            {{
              t(
                "Since you are a new member, private content can take a few minutes to appear."
              )
            }}
          </o-notification>
        </div>
      </header>
    </div>
    <div
      v-if="isCurrentActorAGroupMember && !previewPublic && group"
      class="block-container flex gap-2 flex-wrap mt-3"
    >
      <!-- Private things -->
      <div class="flex-1 m-0 flex flex-col flex-wrap gap-2">
        <!-- Group discussions -->
        <Discussions :group="discussionGroup ?? group" class="flex-1" />
        <!-- Resources -->
        <Resources :group="resourcesGroup ?? group" class="flex-1" />
      </div>
      <!-- Public things -->
      <div class="flex-1 m-0 flex flex-col flex-wrap gap-2">
        <!-- Events -->
        <Events
          :group="group"
          :isModerator="isCurrentActorAGroupModerator"
          class="flex-1"
        />
        <!-- Posts -->
        <Posts
          :group="group"
          :isModerator="isCurrentActorAGroupModerator"
          :isMember="isCurrentActorAGroupMember"
          class="flex-1"
        />
      </div>
    </div>
    <o-notification
      v-else-if="!group && groupLoading === false"
      variant="danger"
    >
      {{ t("No group found") }}
    </o-notification>
    <div v-else-if="group" class="public-container flex flex-col">
      <aside class="group-metadata">
        <div class="sticky">
          <o-notification v-if="group.domain && !isCurrentActorAGroupMember">
            <p>
              {{
                t(
                  "This profile is from another instance, the informations shown here may be incomplete."
                )
              }}
            </p>
            <o-button
              variant="text"
              tag="a"
              :href="group.url"
              rel="noopener noreferrer external"
              >{{ t("View full profile") }}</o-button
            >
          </o-notification>
          <event-metadata-block
            :title="t('About')"
            v-if="group.summary && group.summary !== '<p></p>'"
          >
            <div
              dir="auto"
              class="prose lg:prose-xl dark:prose-invert"
              v-html="group.summary"
            />
          </event-metadata-block>
          <event-metadata-block :title="t('Members')">
            <template #icon>
              <AccountGroup :size="48" />
            </template>
            {{
              t(
                "{count} members",
                {
                  count: group.members?.total,
                },
                group.members?.total
              )
            }}
          </event-metadata-block>
          <event-metadata-block
            v-if="physicalAddress && physicalAddress.url"
            :title="t('Location')"
          >
            <template #icon>
              <o-icon
                v-if="physicalAddress.poiInfos.poiIcon.icon"
                :icon="physicalAddress.poiInfos.poiIcon.icon"
                customSize="48"
              />
              <Earth v-else :size="48" />
            </template>
            <div class="address-wrapper">
              <span
                v-if="!physicalAddress || !addressFullName(physicalAddress)"
                >{{ t("No address defined") }}</span
              >
              <div class="address" v-if="physicalAddress">
                <div>
                  <address dir="auto">
                    <p
                      class="addressDescription"
                      :title="physicalAddress.poiInfos.name"
                    >
                      {{ physicalAddress.poiInfos.name }}
                    </p>
                    <p class="has-text-grey-dark">
                      {{ physicalAddress.poiInfos.alternativeName }}
                    </p>
                  </address>
                </div>
                <o-button
                  class="map-show-button"
                  variant="text"
                  @click="showMap = !showMap"
                  @keyup.enter="showMap = !showMap"
                  v-if="physicalAddress.geom"
                >
                  {{ t("Show map") }}
                </o-button>
              </div>
            </div>
          </event-metadata-block>
        </div>
      </aside>
      <div class="main-content min-w-min flex-auto py-0 px-2">
        <section>
          <h2 class="text-2xl font-bold">{{ t("Upcoming events") }}</h2>
          <div
            class="flex flex-col gap-3"
            v-if="group && organizedEvents.elements.length > 0"
          >
            <event-minimalist-card
              v-for="event in organizedEvents.elements.slice(0, 3)"
              :event="event"
              :key="event.uuid"
              class="organized-event"
            />
          </div>
          <empty-content
            v-else-if="group"
            icon="calendar"
            :inline="true"
            description-classes="flex flex-col items-stretch"
          >
            {{ t("No public upcoming events") }}
            <template #desc>
              <template v-if="isCurrentActorFollowing">
                <i18n-t
                  keypath="You will receive notifications about this group's public activity depending on %{notification_settings}."
                >
                  <template #notification_settings>
                    <router-link :to="{ name: RouteName.NOTIFICATIONS }">{{
                      t("your notification settings")
                    }}</router-link>
                  </template>
                </i18n-t>
              </template>
              <o-button
                tag="router-link"
                class="my-2 self-center"
                variant="text"
                :to="{
                  name: RouteName.GROUP_EVENTS,
                  params: { preferredUsername: usernameWithDomain(group) },
                  query: { showPassedEvents: true },
                }"
                >{{ t("View past events") }}</o-button
              >
            </template>
          </empty-content>
          <!-- <o-skeleton animated v-else-if="$apollo.loading"></o-skeleton> -->
          <div class="flex justify-center">
            <o-button
              tag="router-link"
              class="my-4"
              variant="text"
              v-if="organizedEvents.total > 0"
              :to="{
                name: RouteName.GROUP_EVENTS,
                params: { preferredUsername: usernameWithDomain(group) },
                query: {
                  showPassedEvents: organizedEvents.elements.length === 0,
                },
              }"
              >{{ t("View all events") }}</o-button
            >
          </div>
        </section>
        <section class="flex flex-col items-stretch">
          <h2 class="ml-0 text-2xl font-bold">{{ t("Latest posts") }}</h2>

          <multi-post-list-item
            v-if="
              posts.elements.filter(
                (post) =>
                  !post.draft && post.visibility === PostVisibility.PUBLIC
              ).length > 0
            "
            :posts="
              posts.elements.filter(
                (post) =>
                  !post.draft && post.visibility === PostVisibility.PUBLIC
              )
            "
          />
          <empty-content v-else-if="group" icon="bullhorn" :inline="true">
            {{ t("No posts yet") }}
          </empty-content>
          <!-- <o-skeleton animated v-else-if="$apollo.loading"></o-skeleton> -->
          <o-button
            class="self-center my-2"
            v-if="posts.total > 0"
            tag="router-link"
            variant="text"
            :to="{
              name: RouteName.POSTS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ t("View all posts") }}</o-button
          >
        </section>
      </div>
      <o-modal
        v-if="physicalAddress && physicalAddress.geom"
        v-model:active="showMap"
        :close-button-aria-label="t('Close')"
      >
        <div class="map">
          <map-leaflet
            :coords="physicalAddress.geom"
            :marker="{
              text: physicalAddress.fullName,
              icon: physicalAddress.poiInfos.poiIcon.icon,
            }"
          />
        </div>
      </o-modal>
    </div>
    <o-modal
      v-if="group"
      v-model:active="isReportModalActive"
      :autoFocus="false"
      :trapFocus="false"
    >
      <report-modal
        ref="reportModalRef"
        :on-confirm="reportGroup"
        :title="t('Report this group')"
        :outside-domain="group.domain"
        @close="isReportModalActive = false"
      />
    </o-modal>
    <o-modal v-model:active="isShareModalActive" v-if="group">
      <ShareGroupModal :group="group" />
    </o-modal>
  </div>
</template>

<script lang="ts" setup>
// import EventCard from "@/components/Event/EventCard.vue";
import {
  displayName,
  IActor,
  IFollower,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
// import CompactTodo from "@/components/Todo/CompactTodo.vue";
import EventMinimalistCard from "@/components/Event/EventMinimalistCard.vue";
import MultiPostListItem from "@/components/Post/MultiPostListItem.vue";
import { Address, addressFullName } from "@/types/address.model";
import InvitationsList from "@/components/Group/InvitationsList.vue";
import addMinutes from "date-fns/addMinutes";
import { JOIN_GROUP } from "@/graphql/member";
import { MemberRole, Openness, PostVisibility } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";
import ReportModal from "@/components/Report/ReportModal.vue";
import {
  GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
  PERSON_STATUS_GROUP,
} from "@/graphql/actor";
import LazyImageWrapper from "../../components/Image/LazyImageWrapper.vue";
import EventMetadataBlock from "../../components/Event/EventMetadataBlock.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { Paginate } from "@/types/paginate";
import { IEvent } from "@/types/event.model";
import { IPost } from "@/types/post.model";
import {
  FOLLOW_GROUP,
  UNFOLLOW_GROUP,
  UPDATE_GROUP_FOLLOW,
} from "@/graphql/followers";
import { useAnonymousReportsConfig } from "../../composition/apollo/config";
import { computed, defineAsyncComponent, inject, ref, watch } from "vue";
import { useCurrentActorClient } from "@/composition/apollo/actor";
import { useGroup, useLeaveGroup } from "@/composition/apollo/group";
import { useGroupDiscussionsList } from "@/composition/apollo/discussions";
import { useRouter } from "vue-router";
import { useMutation, useQuery } from "@vue/apollo-composable";
import AccountGroup from "vue-material-design-icons/AccountGroup.vue";
import AccountCircle from "vue-material-design-icons/AccountCircle.vue";
import RSS from "vue-material-design-icons/Rss.vue";
import Share from "vue-material-design-icons/Share.vue";
import CalendarSync from "vue-material-design-icons/CalendarSync.vue";
import Flag from "vue-material-design-icons/Flag.vue";
import ExitToApp from "vue-material-design-icons/ExitToApp.vue";
import AccountMultiplePlus from "vue-material-design-icons/AccountMultiplePlus.vue";
import Earth from "vue-material-design-icons/Earth.vue";
import { useI18n } from "vue-i18n";
import { useCreateReport } from "@/composition/apollo/report";
import { useHead } from "@vueuse/head";
import Discussions from "@/components/Group/Sections/DiscussionsSection.vue";
import Resources from "@/components/Group/Sections/ResourcesSection.vue";
import Posts from "@/components/Group/Sections/PostsSection.vue";
import Events from "@/components/Group/Sections/EventsSection.vue";
import { Dialog } from "@/plugins/dialog";
import { Notifier } from "@/plugins/notifier";
import { useGroupResourcesList } from "@/composition/apollo/resources";

const props = defineProps<{
  preferredUsername: string;
}>();

const { anonymousReportsConfig } = useAnonymousReportsConfig();
const { currentActor } = useCurrentActorClient();
const {
  group,
  loading: groupLoading,
  refetch: refetchGroup,
} = useGroup(props.preferredUsername, { afterDateTime: new Date() });
const router = useRouter();

const { group: discussionGroup } = useGroupDiscussionsList(
  props.preferredUsername
);
const { group: resourcesGroup } = useGroupResourcesList(
  props.preferredUsername,
  { resourcesPage: 1, resourcesLimit: 3 }
);

const { t } = useI18n({ useScope: "global" });

// const { person } = usePersonStatusGroup(group);

const { result, subscribeToMore } = useQuery<{
  person: IPerson;
}>(
  PERSON_STATUS_GROUP,
  () => ({
    id: currentActor.value?.id,
    group: usernameWithDomain(group.value),
  }),
  () => ({
    enabled:
      currentActor.value?.id !== undefined &&
      currentActor.value?.id !== null &&
      group.value?.preferredUsername !== undefined &&
      usernameWithDomain(group.value) !== "",
  })
);
subscribeToMore<{ actorId: string; group: string }>({
  document: GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
  variables: {
    actorId: currentActor.value?.id as string,
    group: usernameWithDomain(group.value),
  },
});
const person = computed(() => result.value?.person);

const MapLeaflet = defineAsyncComponent(
  () => import("@/components/LeafletMap.vue")
);
const ShareGroupModal = defineAsyncComponent(
  () => import("@/components/Group/ShareGroupModal.vue")
);

const showMap = ref(false);
const isReportModalActive = ref(false);
const reportModalRef = ref();
const isShareModalActive = ref(false);
const previewPublic = ref(false);

const notifier = inject<Notifier>("notifier");

watch(
  currentActor,
  (watchedCurrentActor: IActor | undefined, oldActor: IActor | undefined) => {
    if (
      watchedCurrentActor?.id &&
      oldActor &&
      watchedCurrentActor?.id !== oldActor.id
    ) {
      refetchGroup();
    }
  }
);

const { mutate: joinGroupMutation, onError: onJoinGroupError } =
  useMutation(JOIN_GROUP);

const joinGroup = async (): Promise<void> => {
  if (!currentActor.value?.id) {
    router.push({
      name: RouteName.GROUP_JOIN,
      params: { preferredUsername: usernameWithDomain(group.value) },
    });
    return;
  }
  const [groupUsername, currentActorId] = [
    usernameWithDomain(group.value),
    currentActor.value?.id,
  ];

  joinGroupMutation(
    {
      groupId: group.value?.id,
    },
    {
      refetchQueries: [
        {
          query: PERSON_STATUS_GROUP,
          variables: {
            id: currentActorId,
            group: groupUsername,
          },
        },
      ],
    }
  );

  onJoinGroupError((error) => {
    if (error.graphQLErrors && error.graphQLErrors.length > 0) {
      notifier?.error(error.graphQLErrors[0].message);
    }
  });
};

const dialog = inject<Dialog>("dialog");

const openLeaveGroupModal = async (): Promise<void> => {
  dialog?.confirm({
    variant: "danger",
    title: t("Leave group"),
    message: t(
      "Are you sure you want to leave the group {groupName}? You'll loose access to this group's private content. This action cannot be undone.",
      { groupName: `<b>${displayName(group.value)}</b>` }
    ),
    onConfirm: leaveGroup,
    confirmText: t("Leave group"),
    cancelText: t("Cancel"),
  });
};

const {
  mutate: leaveGroupMutation,
  onError: onLeaveGroupError,
  onDone: onLeaveGroupDone,
} = useLeaveGroup();

const leaveGroup = () => {
  console.debug("called leaveGroup");

  const [groupFederatedUsername, currentActorId] = [
    usernameWithDomain(group.value),
    currentActor.value?.id,
  ];

  leaveGroupMutation(
    {
      groupId: group.value?.id,
    },
    {
      refetchQueries: [
        {
          query: PERSON_STATUS_GROUP,
          variables: {
            id: currentActorId,
            group: groupFederatedUsername,
          },
        },
      ],
    }
  );
};

onLeaveGroupError((error: any) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

onLeaveGroupDone(() => {
  console.debug("done");
});

const { mutate: followGroupMutation, onError: onFollowGroupError } =
  useMutation(FOLLOW_GROUP, () => ({
    refetchQueries: [
      {
        query: PERSON_STATUS_GROUP,
        variables: {
          id: currentActor.value?.id,
          group: usernameWithDomain(group.value),
        },
      },
    ],
  }));

onFollowGroupError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const followGroup = async (): Promise<void> => {
  if (!currentActor.value?.id) {
    router.push({
      name: RouteName.GROUP_FOLLOW,
      params: {
        preferredUsername: usernameWithDomain(group.value),
      },
    });
    return;
  }
  followGroupMutation({
    groupId: group.value?.id,
  });
};

const { mutate: unfollowGroupMutation, onError: onUnfollowGroupError } =
  useMutation(UNFOLLOW_GROUP, () => ({
    refetchQueries: [
      {
        query: PERSON_STATUS_GROUP,
        variables: {
          id: currentActor.value?.id,
          group: usernameWithDomain(group.value),
        },
      },
    ],
  }));

onUnfollowGroupError((error) => {
  if (error.graphQLErrors && error.graphQLErrors.length > 0) {
    notifier?.error(error.graphQLErrors[0].message);
  }
});

const unFollowGroup = async (): Promise<void> => {
  console.debug("unfollow group");

  unfollowGroupMutation({
    groupId: group.value?.id,
  });
};

const { mutate: updateGroupFollowMutation } = useMutation(UPDATE_GROUP_FOLLOW);

const toggleFollowNotify = () => {
  updateGroupFollowMutation({
    followId: currentActorFollow.value?.id,
    notify: !isCurrentActorFollowingNotify.value,
  });
};

const {
  mutate: createReportMutation,
  onError: onCreateReportError,
  onDone: onCreateReportDone,
} = useCreateReport();

const reportGroup = (content: string, forward: boolean) => {
  isReportModalActive.value = false;
  console.debug("report group", {
    reportedId: group.value?.id ?? "",
    content,
    forward,
  });

  createReportMutation({
    reportedId: group.value?.id ?? "",
    content,
    forward,
  });
};

onCreateReportDone(() => {
  notifier?.success(
    t("Group {groupTitle} reported", { groupTitle: groupTitle.value })
  );
});

onCreateReportError((error: any) => {
  console.error(error);
  notifier?.error(
    t("Error while reporting group {groupTitle}", {
      groupTitle: groupTitle.value,
    })
  );
});

const triggerShare = (): void => {
  if (navigator.share) {
    navigator
      .share({
        title: displayName(group.value),
        url: group.value?.url,
      })
      .then(() => console.debug("Successful share"))
      .catch((error: any) => console.debug("Error sharing", error));
  } else {
    isShareModalActive.value = true;
    // send popup
  }
};

const groupTitle = computed((): undefined | string => {
  return displayName(group.value);
});

const groupSummary = computed((): undefined | string => {
  return group.value?.summary;
});

useHead({
  title: computed(() => groupTitle.value ?? ""),
  meta: [{ name: "description", content: computed(() => groupSummary.value) }],
});

const personMemberships = computed(
  () => person.value?.memberships ?? { total: 0, elements: [] }
);

const groupMember = computed((): IMember | undefined => {
  if (personMemberships.value?.total > 0) {
    return personMemberships.value?.elements[0];
  }
  return undefined;
});

const isCurrentActorARejectedGroupMember = computed((): boolean => {
  return personMemberships.value.elements
    .filter((membership) => membership.role === MemberRole.REJECTED)
    .map(({ parent: { id } }) => id)
    .includes(group.value?.id);
});

const isCurrentActorAnInvitedGroupMember = computed((): boolean => {
  return personMemberships.value.elements
    .filter((membership) => membership.role === MemberRole.INVITED)
    .map(({ parent: { id } }) => id)
    .includes(group.value?.id);
});

/**
 * New members, if on a different server,
 * can take a while to refresh the group and fetch all private data
 */
const isCurrentActorARecentMember = computed((): boolean => {
  return (
    groupMember.value !== undefined &&
    groupMember.value?.role === MemberRole.MEMBER &&
    addMinutes(new Date(`${groupMember.value?.updatedAt}Z`), 10) > new Date()
  );
});

const isCurrentActorOnADifferentDomainThanGroup = computed((): boolean => {
  return group.value?.domain !== null;
});

const members = computed((): IMember[] => {
  return (
    (group.value?.members?.elements ?? []).filter(
      (member: IMember) =>
        ![
          MemberRole.INVITED,
          MemberRole.REJECTED,
          MemberRole.NOT_APPROVED,
        ].includes(member.role)
    ) ?? []
  );
});

const physicalAddress = computed((): Address | null => {
  if (!group.value?.physicalAddress) return null;
  return new Address(group.value?.physicalAddress);
});

const ableToReport = computed((): boolean => {
  return anonymousReportsConfig.value?.allowed === true;
});

const organizedEvents = computed((): Paginate<IEvent> => {
  return {
    total: group.value?.organizedEvents.total ?? 0,
    elements:
      group.value?.organizedEvents.elements.filter((event: IEvent) => {
        if (previewPublic.value) {
          return !event.draft; // TODO when events get visibility access add visibility constraint like below for posts
        }
        return true;
      }) ?? [],
  };
});

const posts = computed((): Paginate<IPost> => {
  return {
    total: group.value?.posts.total ?? 0,
    elements:
      group.value?.posts.elements.filter((post: IPost) => {
        if (previewPublic.value || !isCurrentActorAGroupMember.value) {
          return !post.draft && post.visibility == PostVisibility.PUBLIC;
        }
        return true;
      }) ?? [],
  };
});

const showFollowButton = computed((): boolean => {
  return !isCurrentActorFollowing.value || previewPublic.value;
});

const showJoinButton = computed((): boolean => {
  return !isCurrentActorAGroupMember.value || previewPublic.value;
});

const isGroupInviteOnly = computed((): boolean => {
  return (
    (!isCurrentActorAGroupMember.value || previewPublic) &&
    group.value?.openness === Openness.INVITE_ONLY
  );
});

const areGroupMembershipsModerated = computed((): boolean => {
  return (
    (!isCurrentActorAGroupMember.value || previewPublic) &&
    group.value?.openness === Openness.MODERATED
  );
});

const doesGroupManuallyApprovesFollowers = computed((): boolean | undefined => {
  return (
    (!isCurrentActorAGroupMember.value || previewPublic) &&
    group.value?.manuallyApprovesFollowers
  );
});

const isCurrentActorAGroupAdmin = computed((): boolean => {
  return hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
});

const isCurrentActorAGroupModerator = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
  ]);
});

const isCurrentActorAGroupMember = computed((): boolean => {
  return hasCurrentActorThisRole([
    MemberRole.MODERATOR,
    MemberRole.ADMINISTRATOR,
    MemberRole.MEMBER,
  ]);
});

const isCurrentActorAPendingGroupMember = computed((): boolean => {
  return hasCurrentActorThisRole([MemberRole.NOT_APPROVED]);
});

const currentActorFollow = computed((): IFollower | undefined => {
  if (person?.value?.follows?.total && person?.value?.follows?.total > 0) {
    return person?.value?.follows?.elements[0];
  }
  return undefined;
});

const isCurrentActorFollowing = computed((): boolean => {
  return currentActorFollow.value?.approved === true;
});

const isCurrentActorPendingFollow = computed((): boolean => {
  return currentActorFollow.value?.approved === false;
});

const isCurrentActorFollowingNotify = computed((): boolean => {
  return (
    isCurrentActorFollowing.value && currentActorFollow.value?.notify === true
  );
});

const hasCurrentActorThisRole = (givenRole: string | string[]): boolean => {
  const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
  return (
    personMemberships.value?.total > 0 &&
    roles.includes(personMemberships.value?.elements[0].role)
  );
};

watch(isCurrentActorAGroupMember, () => {
  refetchGroup();
});
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
div.container {
  .block-container {
    display: flex;
    flex-wrap: wrap;
    margin-top: 15px;

    &.presentation {
      padding: 0 0 10px;
      position: relative;
      flex-direction: column;

      & > *:not(img) {
        position: relative;
        z-index: 2;
      }

      & > .banner-container {
        display: flex;
        justify-content: center;
        height: 30vh;
        :deep(img) {
          width: 100%;
          height: 100%;
          object-fit: cover;
          object-position: 50% 50%;
        }
      }
    }

    div.address {
      flex: 1;
      text-align: right;
      justify-content: flex-end;
      display: flex;

      .map-show-button {
        cursor: pointer;
      }

      address {
        font-style: normal;

        span.addressDescription {
          text-overflow: ellipsis;
          white-space: nowrap;
          flex: 1 0 auto;
          min-width: 100%;
          max-width: 4rem;
          overflow: hidden;
        }

        :not(.addressDescription) {
          color: rgba(46, 62, 72, 0.6);
          flex: 1;
          min-width: 100%;
        }
      }
    }

    .header {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      flex-direction: column;
      flex: 1;
      margin: 0;
      align-items: center;

      .group-metadata {
        display: flex;
        flex-direction: row;
        flex-wrap: wrap;
        justify-content: center;

        .members {
          div {
            display: flex;
          }

          figure:not(:first-child) {
            @include margin-left(-10px);
          }
        }
      }
    }
  }

  .public-container {
    display: flex;
    flex-wrap: wrap;
    flex-direction: row-reverse;
    padding: 0;
    margin-top: 1rem;

    .group-metadata {
      min-width: 20rem;
      flex: 1;
      // @include padding-left(1rem);
      // @include mobile {
      //   @include padding-left(0);
      // }

      .sticky {
        position: sticky;
        // background: white;
        top: 50px;
        padding: 1rem;
      }
    }

    section {
      margin-top: 0;
    }
  }
}
.map {
  height: 60vh;
  width: 100%;
}
</style>
