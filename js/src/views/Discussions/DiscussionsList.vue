<template>
  <div class="container section" v-if="group">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MY_GROUPS }">{{
            $t("My groups")
          }}</router-link>
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.DISCUSSION_LIST,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Discussions") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section v-if="isCurrentActorAGroupMember">
      <p>
        {{
          $t(
            "Keep the entire conversation about a specific topic together on a single page."
          )
        }}
      </p>
      <b-button
        tag="router-link"
        :to="{
          name: RouteName.CREATE_DISCUSSION,
          params: { preferredUsername },
        }"
        >{{ $t("New discussion") }}</b-button
      >
      <div v-if="group.discussions.elements.length > 0">
        <discussion-list-item
          :discussion="discussion"
          v-for="discussion in group.discussions.elements"
          :key="discussion.id"
        />
      </div>
      <empty-content v-else icon="chat">
        {{ $t("There's no discussions yet") }}
      </empty-content>
    </section>
    <section class="section" v-else>
      <empty-content icon="chat">
        {{ $t("Only group members can access discussions") }}
        <template #desc>
          <router-link
            :to="{ name: RouteName.GROUP, params: { preferredUsername } }"
          >
            {{ $t("Return to the group page") }}
          </router-link>
        </template>
      </empty-content>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/group";
import { IActor, IGroup, IPerson, usernameWithDomain } from "@/types/actor";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import RouteName from "../../router/name";
import { MemberRole } from "@/types/enums";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED } from "@/graphql/event";
import { IMember } from "@/types/actor/member.model";
import EmptyContent from "@/components/Utils/EmptyContent.vue";

@Component({
  components: { DiscussionListItem, EmptyContent },
  apollo: {
    group: {
      query: FETCH_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          name: this.preferredUsername,
        };
      },
      skip() {
        return !this.preferredUsername;
      },
    },
    person: {
      query: PERSON_MEMBERSHIPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
        };
      },
      subscribeToMore: {
        document: GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
        variables() {
          return {
            actorId: this.currentActor.id,
          };
        },
        skip() {
          return !this.currentActor || !this.currentActor.id;
        },
      },
      skip() {
        return !this.currentActor || !this.currentActor.id;
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.$t("Discussions") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class DiscussionsList extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  person!: IPerson;

  group!: IGroup;

  currentActor!: IActor;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

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

  get isCurrentActorAGroupMember(): boolean {
    return (
      this.groupMemberships !== undefined &&
      this.groupMemberships.includes(this.group.id)
    );
  }
}
</script>
<style lang="scss">
div.container.section {
  background: white;
}
</style>
