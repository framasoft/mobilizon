<template>
  <div class="container is-widescreen">
    <div class="header">
      <nav class="breadcrumb" aria-label="breadcrumbs">
        <ul>
          <li>
            <router-link :to="{ name: RouteName.MY_GROUPS }">{{
              $t("My groups")
            }}</router-link>
          </li>
          <li class="is-active">
            <router-link
              v-if="group.preferredUsername"
              :to="{
                name: RouteName.GROUP,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ group.name }}</router-link
            >
            <b-skeleton v-else :animated="true"></b-skeleton>
          </li>
        </ul>
      </nav>
      <invitations
        v-if="isCurrentActorAnInvitedGroupMember"
        :invitations="[groupMember]"
        @acceptInvitation="acceptInvitation"
        @reject-invitation="rejectInvitation"
      />
      <b-message v-if="isCurrentActorARejectedGroupMember" type="is-danger">
        {{ $t("You have been removed from this group's members.") }}
      </b-message>
      <b-message
        v-if="isCurrentActorAGroupMember && isCurrentActorARecentMember"
        type="is-info"
      >
        {{
          $t(
            "Since you are a new member, private content can take a few minutes to appear."
          )
        }}
      </b-message>
      <header class="block-container presentation">
        <div class="block-column media">
          <div class="media-left">
            <figure class="image is-128x128" v-if="group.avatar">
              <img class="is-rounded" :src="group.avatar.url" alt="" />
            </figure>
            <b-icon v-else size="is-large" icon="account-group" />
          </div>
          <div class="media-content">
            <h1 v-if="group.name">{{ group.name }}</h1>
            <b-skeleton v-else :animated="true" />
            <small class="has-text-grey" v-if="group.preferredUsername"
              >@{{ usernameWithDomain(group) }}</small
            >
            <b-skeleton v-else :animated="true" />
            <br />
            <div class="buttons">
              <router-link
                v-if="isCurrentActorAGroupAdmin"
                :to="{
                  name: RouteName.GROUP_PUBLIC_SETTINGS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                class="button is-outlined"
                >{{ $t("Group settings") }}</router-link
              >
            </div>
          </div>
        </div>
        <div class="block-column members" v-if="isCurrentActorAGroupMember">
          <div>
            <figure
              class="image is-48x48"
              :title="
                $t(`@{username} ({role})`, {
                  username: usernameWithDomain(member.actor),
                  role: member.role,
                })
              "
              v-for="member in members"
              :key="member.actor.id"
            >
              <img
                class="is-rounded"
                :src="member.actor.avatar.url"
                v-if="member.actor.avatar"
                alt
              />
              <b-icon v-else size="is-large" icon="account-circle" />
            </figure>
          </div>
          <p>
            {{ $t("{count} team members", { count: group.members.total }) }}
            <router-link
              v-if="isCurrentActorAGroupAdmin"
              :to="{
                name: RouteName.GROUP_MEMBERS_SETTINGS,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ $t("Add / Remove…") }}</router-link
            >
          </p>
        </div>
        <div class="block-column address" v-else>
          <address v-if="physicalAddress">
            <p
              class="addressDescription"
              :title="physicalAddress.poiInfos.name"
            >
              {{ physicalAddress.poiInfos.name }}
            </p>
            <p>{{ physicalAddress.poiInfos.alternativeName }}</p>
          </address>
          <span
            class="map-show-button"
            @click="showMap = !showMap"
            v-if="physicalAddress && physicalAddress.geom"
            >{{ $t("Show map") }}</span
          >
          <p class="buttons">
            <b-tooltip
              v-if="group.openness !== Openness.OPEN"
              :label="$t('This group is invite-only')"
              position="is-bottom"
            >
              <b-button disabled type="is-primary">{{
                $t("Join group")
              }}</b-button></b-tooltip
            >
            <b-button
              v-else-if="currentActor.id"
              @click="joinGroup"
              type="is-primary"
              >{{ $t("Join group") }}</b-button
            >
            <b-button
              tag="router-link"
              :to="{
                name: RouteName.GROUP_JOIN,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              v-else
              type="is-primary"
              >{{ $t("Join group") }}</b-button
            >
            <b-dropdown
              class="menu-dropdown"
              aria-role="list"
              position="is-bottom-left"
            >
              <b-button
                slot="trigger"
                role="button"
                icon-right="dots-horizontal"
              >
              </b-button>
              <b-dropdown-item
                aria-role="listitem"
                v-if="ableToReport"
                @click="isReportModalActive = true"
              >
                <span>
                  {{ $t("Report") }}
                  <b-icon icon="flag" />
                </span>
              </b-dropdown-item>
              <hr class="dropdown-divider" />
              <b-dropdown-item has-link aria-role="listitem">
                <a
                  :href="`@${preferredUsername}/feed/atom`"
                  :title="$t('Atom feed for events and posts')"
                >
                  {{ $t("RSS/Atom Feed") }}
                  <b-icon icon="rss" />
                </a>
              </b-dropdown-item>
              <b-dropdown-item has-link aria-role="listitem">
                <a
                  :href="`@${preferredUsername}/feed/ics`"
                  :title="$t('ICS feed for events')"
                >
                  {{ $t("ICS/WebCal Feed") }}
                  <b-icon icon="calendar-sync" />
                </a>
              </b-dropdown-item>
            </b-dropdown>
          </p>
        </div>
        <img
          v-if="group.banner && group.banner.url"
          :src="group.banner.url"
          alt=""
        />
      </header>
    </div>
    <div v-if="isCurrentActorAGroupMember" class="block-container">
      <!-- Private things -->
      <div class="block-column">
        <!-- Group discussions -->
        <group-section
          :title="$t('Discussions')"
          icon="chat"
          :route="{
            name: RouteName.DISCUSSION_LIST,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div v-if="group.discussions.total > 0">
              <discussion-list-item
                v-for="discussion in group.discussions.elements"
                :key="discussion.id"
                :discussion="discussion"
              />
            </div>
            <div v-else class="content has-text-grey has-text-centered">
              <p>{{ $t("No discussions yet") }}</p>
            </div>
          </template>
          <template v-slot:create>
            <router-link
              :to="{
                name: RouteName.CREATE_DISCUSSION,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-primary"
              >{{ $t("+ Start a discussion") }}</router-link
            >
          </template>
        </group-section>
        <!-- Resources -->
        <group-section
          :title="$t('Resources')"
          icon="link"
          :route="{
            name: RouteName.RESOURCE_FOLDER_ROOT,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div v-if="group.resources.elements.length > 0">
              <div
                v-for="resource in group.resources.elements"
                :key="resource.id"
              >
                <resource-item
                  :resource="resource"
                  v-if="resource.type !== 'folder'"
                  :inline="true"
                />
                <folder-item
                  :resource="resource"
                  :group="group"
                  v-else
                  :inline="true"
                />
              </div>
            </div>
            <div
              v-else-if="group"
              class="content has-text-grey has-text-centered"
            >
              <p>{{ $t("No resources yet") }}</p>
            </div>
          </template>
          <template v-slot:create>
            <router-link
              :to="{
                name: RouteName.RESOURCE_FOLDER_ROOT,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-primary"
              >{{ $t("+ Add a resource") }}</router-link
            >
          </template>
        </group-section>
      </div>
      <!-- Public things -->
      <div class="block-column">
        <!-- Events -->
        <group-section
          :title="$t('Upcoming events')"
          icon="calendar"
          :privateSection="false"
          :route="{
            name: RouteName.GROUP_EVENTS,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div
              class="organized-events-wrapper"
              v-if="group && group.organizedEvents.total > 0"
            >
              <EventMinimalistCard
                v-for="event in group.organizedEvents.elements"
                :event="event"
                :key="event.uuid"
                class="organized-event"
              />
            </div>
            <div
              v-else-if="group"
              class="content has-text-grey has-text-centered"
            >
              <p>{{ $t("No public upcoming events") }}</p>
            </div>
            <b-skeleton animated v-else></b-skeleton>
          </template>
          <template v-slot:create>
            <router-link
              v-if="isCurrentActorAGroupModerator"
              :to="{
                name: RouteName.CREATE_EVENT,
              }"
              class="button is-primary"
              >{{ $t("+ Create an event") }}</router-link
            >
          </template>
        </group-section>
        <!-- Posts -->
        <group-section
          :title="$t('Public page')"
          icon="bullhorn"
          :privateSection="false"
          :route="{
            name: RouteName.POSTS,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div v-if="group.posts.total > 0" class="posts-wrapper">
              <post-list-item
                v-for="post in group.posts.elements"
                :key="post.id"
                :post="post"
              />
            </div>
            <div
              v-else-if="group"
              class="content has-text-grey has-text-centered"
            >
              <p>{{ $t("No posts yet") }}</p>
            </div>
          </template>
          <template v-slot:create>
            <router-link
              v-if="isCurrentActorAGroupModerator"
              :to="{
                name: RouteName.POST_CREATE,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-primary"
              >{{ $t("+ Post a public message") }}</router-link
            >
          </template>
        </group-section>
      </div>
    </div>
    <b-message v-else-if="!group && $apollo.loading === false" type="is-danger">
      {{ $t("No group found") }}
    </b-message>
    <div v-else class="public-container">
      <section>
        <subtitle>{{ $t("About") }}</subtitle>
        <div
          v-html="group.summary"
          v-if="group.summary && group.summary !== '<p></p>'"
        />
        <div v-else-if="group" class="content has-text-grey has-text-centered">
          <p>{{ $t("This group doesn't have a description yet.") }}</p>
        </div>
      </section>
      <section>
        <subtitle>{{ $t("Upcoming events") }}</subtitle>
        <div
          class="organized-events-wrapper"
          v-if="group && group.organizedEvents.total > 0"
        >
          <EventMinimalistCard
            v-for="event in group.organizedEvents.elements"
            :event="event"
            :key="event.uuid"
            class="organized-event"
          />
        </div>
        <div
          v-else-if="group && group.organizedEvents.elements.length == 0"
          class="content has-text-grey has-text-centered"
        >
          <p>{{ $t("No public upcoming events") }}</p>
        </div>
        <div v-else-if="group" class="content has-text-grey has-text-centered">
          <p>{{ $t("No public upcoming events") }}</p>
        </div>
        <b-skeleton animated v-else-if="$apollo.loading"></b-skeleton>
        <router-link
          v-if="group.organizedEvents.total > 0"
          :to="{
            name: RouteName.GROUP_EVENTS,
            params: { preferredUsername: usernameWithDomain(group) },
            query: { future: group.organizedEvents.elements.length > 0 },
          }"
          >{{ $t("View all events") }}</router-link
        >
      </section>
      <section>
        <subtitle>{{ $t("Latest posts") }}</subtitle>
        <div v-if="group.posts.total > 0" class="posts-wrapper">
          <post-list-item
            v-for="post in group.posts.elements"
            :key="post.id"
            :post="post"
          />
        </div>
        <div v-else-if="group" class="content has-text-grey has-text-centered">
          <p>{{ $t("No posts yet") }}</p>
        </div>
        <b-skeleton animated v-else-if="$apollo.loading"></b-skeleton>
        <router-link
          v-if="group.posts.total > 0"
          :to="{
            name: RouteName.POSTS,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
          >{{ $t("View all posts") }}</router-link
        >
      </section>
      <b-modal
        v-if="physicalAddress && physicalAddress.geom"
        :active.sync="showMap"
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
      </b-modal>
      <b-modal
        :active.sync="isReportModalActive"
        has-modal-card
        ref="reportModal"
      >
        <report-modal
          :on-confirm="reportGroup"
          :title="$t('Report this group')"
          :outside-domain="group.domain"
          @close="$refs.reportModal.close()"
        />
      </b-modal>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Watch } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { IActor, usernameWithDomain } from "@/types/actor";
import Subtitle from "@/components/Utils/Subtitle.vue";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import EventMinimalistCard from "@/components/Event/EventMinimalistCard.vue";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import PostListItem from "@/components/Post/PostListItem.vue";
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import { Address } from "@/types/address.model";
import Invitations from "@/components/Group/Invitations.vue";
import addMinutes from "date-fns/addMinutes";
import { CONFIG } from "@/graphql/config";
import { CREATE_REPORT } from "@/graphql/report";
import { IReport } from "@/types/report.model";
import { IConfig } from "@/types/config.model";
import GroupMixin from "@/mixins/group";
import { mixins } from "vue-class-component";
import { JOIN_GROUP } from "@/graphql/member";
import { MemberRole, Openness } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";
import GroupSection from "../../components/Group/GroupSection.vue";
import ReportModal from "../../components/Report/ReportModal.vue";

@Component({
  apollo: {
    config: CONFIG,
  },
  components: {
    DiscussionListItem,
    PostListItem,
    EventMinimalistCard,
    CompactTodo,
    Subtitle,
    EventCard,
    FolderItem,
    ResourceItem,
    GroupSection,
    Invitations,
    ReportModal,
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "../../components/Map.vue"),
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.groupTitle,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
      meta: [
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        { name: "description", content: this.groupSummary },
      ],
    };
  },
})
export default class Group extends mixins(GroupMixin) {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  config!: IConfig;

  loading = true;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  Openness = Openness;

  showMap = false;

  isReportModalActive = false;

  @Watch("currentActor")
  watchCurrentActor(currentActor: IActor, oldActor: IActor): void {
    if (currentActor.id && oldActor && currentActor.id !== oldActor.id) {
      this.$apollo.queries.group.refetch();
    }
  }

  async joinGroup(): Promise<void> {
    this.$apollo.mutate({
      mutation: JOIN_GROUP,
      variables: {
        groupId: this.group.id,
      },
    });
  }

  acceptInvitation(): void {
    if (this.groupMember) {
      const index = this.person.memberships.elements.findIndex(
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        ({ id }: IMember) => id === this.groupMember.id
      );
      const member = this.groupMember;
      member.role = MemberRole.MEMBER;
      this.person.memberships.elements.splice(index, 1, member);
      this.$apollo.queries.group.refetch();
    }
  }

  rejectInvitation({ id: memberId }: { id: string }): void {
    const index = this.person.memberships.elements.findIndex(
      (membership) =>
        membership.role === MemberRole.INVITED && membership.id === memberId
    );
    if (index > -1) {
      this.person.memberships.elements.splice(index, 1);
      this.person.memberships.total -= 1;
    }
  }

  async reportGroup(content: string, forward: boolean): Promise<void> {
    this.isReportModalActive = false;
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.$refs.reportModal.close();
    const groupTitle = this.group.name || usernameWithDomain(this.group);
    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          reportedId: this.group.id,
          content,
          forward,
        },
      });
      this.$notifier.success(
        this.$t("Group {groupTitle} reported", { groupTitle }) as string
      );
    } catch (error) {
      console.error(error);
      this.$notifier.error(
        this.$t("Error while reporting group {groupTitle}", {
          groupTitle,
        }) as string
      );
    }
  }

  get groupTitle(): undefined | string {
    if (!this.group) return undefined;
    return this.group.name || this.group.preferredUsername;
  }

  get groupSummary(): undefined | string {
    if (!this.group) return undefined;
    return this.group.summary;
  }

  get groupMember(): IMember | undefined {
    if (!this.person || !this.person.id) return undefined;
    return this.person.memberships.elements.find(
      ({ parent: { id } }) => id === this.group.id
    );
  }

  get groupMemberships(): (string | undefined)[] {
    if (!this.person || !this.person.id) return [];
    return this.person.memberships.elements
      .filter(
        (membership: IMember) =>
          ![
            MemberRole.REJECTED,
            MemberRole.NOT_APPROVED,
            MemberRole.INVITED,
          ].includes(membership.role)
      )
      .map(({ parent: { id } }) => id);
  }

  @Watch("isCurrentActorAGroupMember")
  refetchGroupData(): void {
    this.$apollo.queries.group.refetch();
  }

  get isCurrentActorAGroupMember(): boolean {
    return (
      this.groupMemberships !== undefined &&
      this.groupMemberships.includes(this.group.id)
    );
  }

  get isCurrentActorARejectedGroupMember(): boolean {
    return (
      this.person &&
      this.person.memberships.elements
        .filter((membership) => membership.role === MemberRole.REJECTED)
        .map(({ parent: { id } }) => id)
        .includes(this.group.id)
    );
  }

  get isCurrentActorAnInvitedGroupMember(): boolean {
    return (
      this.person &&
      this.person.memberships.elements
        .filter((membership) => membership.role === MemberRole.INVITED)
        .map(({ parent: { id } }) => id)
        .includes(this.group.id)
    );
  }

  /**
   * New members, if on a different server,
   * can take a while to refresh the group and fetch all private data
   */
  get isCurrentActorARecentMember(): boolean {
    return (
      this.groupMember !== undefined &&
      this.groupMember.role === MemberRole.MEMBER &&
      addMinutes(new Date(`${this.groupMember.updatedAt}Z`), 10) > new Date()
    );
  }

  get members(): IMember[] {
    return this.group.members.elements.filter(
      (member) =>
        ![
          MemberRole.INVITED,
          MemberRole.REJECTED,
          MemberRole.NOT_APPROVED,
        ].includes(member.role)
    );
  }

  get physicalAddress(): Address | null {
    if (!this.group.physicalAddress) return null;
    return new Address(this.group.physicalAddress);
  }

  get ableToReport(): boolean {
    return (
      this.config &&
      (this.currentActor.id !== undefined ||
        this.config.anonymous.reports.allowed)
    );
  }
}
</script>
<style lang="scss" scoped>
div.container {
  background: white;
  margin-bottom: 3rem;
  padding: 2rem 0;

  .header,
  .public-container {
    margin: auto 1rem;
    display: flex;
    flex-direction: column;
  }

  .block-container {
    display: flex;
    flex-wrap: wrap;
    margin-top: 15px;

    &.presentation {
      border: 2px solid $purple-2;
      padding: 10px 0;
      position: relative;

      h1 {
        color: $purple-1;
        font-size: 2rem;
        font-weight: 500;
      }

      .button.is-outlined {
        border-color: $purple-2;
      }

      & > *:not(img) {
        position: relative;
        z-index: 2;
      }

      & > img {
        position: absolute;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        opacity: 0.3;
        object-fit: cover;
        object-position: 50% 50%;
      }
    }

    .members {
      display: flex;
      flex-direction: column;

      div {
        display: flex;
      }

      figure:not(:first-child) {
        margin-left: -10px;
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

      p.buttons {
        margin-top: 1rem;
        justify-content: end;
        align-content: space-between;

        & > span {
          margin-right: 0.5rem;
        }
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

    .block-column {
      flex: 1;
      margin: 0 1rem;

      section {
        .posts-wrapper {
          padding-bottom: 1rem;
        }

        .organized-events-wrapper {
          display: flex;
          flex-wrap: wrap;

          .organized-event {
            margin: 0.25rem 0;
          }
        }

        &.presentation {
          .media-left {
            span.icon.is-large {
              height: 5rem;
              width: 5rem;

              ::v-deep i.mdi.mdi-account-group.mdi-48px:before {
                font-size: 100px;
              }
            }
          }

          .media-content {
            h2 {
              color: #3c376e;
              font-family: "Liberation Sans", "Helvetica Neue", Roboto,
                Helvetica, Arial, serif;
              font-size: 1.5rem;
              font-weight: 700;
            }
          }
        }
      }
    }
  }

  .public-container {
    section {
      margin-top: 2rem;
    }
  }

  .menu-dropdown {
    ::v-deep .dropdown-item,
    ::v-deep .has-link a {
      padding-right: 1rem;
    }
  }
}
</style>
