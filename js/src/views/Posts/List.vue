<template>
  <div class="container section" v-if="group">
    <nav class="breadcrumb" aria-label="breadcrumbs" v-if="group">
      <ul>
        <li>
          <router-link
            v-if="group"
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name || group.preferredUsername }}</router-link
          >
          <b-skeleton v-else :animated="true"></b-skeleton>
        </li>
        <li class="is-active">
          <router-link
            v-if="group"
            :to="{
              name: RouteName.POSTS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Posts") }}</router-link
          >
          <b-skeleton v-else :animated="true"></b-skeleton>
        </li>
      </ul>
    </nav>
    <section>
      <div class="intro">
        <p v-if="isCurrentActorMember">
          {{
            $t(
              "A place to publish something to the whole world, your community or just your group members."
            )
          }}
        </p>
        <p v-if="isCurrentActorMember">
          {{ $t("Only group moderators can create, edit and delete posts.") }}
        </p>
        <router-link
          v-if="isCurrentActorAGroupModerator"
          :to="{
            name: RouteName.POST_CREATE,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
          class="button is-primary"
          >{{ $t("+ Post a public message") }}</router-link
        >
      </div>
      <div class="post-list">
        <post-element-item
          v-for="post in group.posts.elements"
          :key="post.id"
          :post="post"
          :isCurrentActorMember="isCurrentActorMember"
        />
      </div>
      <b-loading :active.sync="$apollo.loading"></b-loading>
      <b-message
        v-if="group.posts.elements.length === 0 && $apollo.loading === false"
        type="is-danger"
      >
        {{ $t("No posts found") }}
      </b-message>
      <b-pagination
        :total="group.posts.total"
        v-model="postsPage"
        :per-page="POSTS_PAGE_LIMIT"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
      >
      </b-pagination>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";
import { IMember } from "@/types/actor/member.model";
import { FETCH_GROUP_POSTS } from "../../graphql/post";
import { Paginate } from "../../types/paginate";
import { IPost } from "../../types/post.model";
import { IGroup, IPerson, usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import PostElementItem from "../../components/Post/PostElementItem.vue";

const POSTS_PAGE_LIMIT = 10;

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    memberships: {
      query: PERSON_MEMBERSHIPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
        };
      },
      update: (data) => data.person.memberships.elements,
      skip() {
        return !this.currentActor || !this.currentActor.id;
      },
    },
    group: {
      query: FETCH_GROUP_POSTS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          preferredUsername: this.preferredUsername,
          page: this.postsPage,
          limit: POSTS_PAGE_LIMIT,
        };
      },
      skip() {
        return !this.preferredUsername;
      },
    },
  },
  components: {
    PostElementItem,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.$t("My groups") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class PostList extends mixins(GroupMixin) {
  @Prop({ required: true, type: String }) preferredUsername!: string;

  group!: IGroup;

  posts!: Paginate<IPost>;

  memberships!: IMember[];

  currentActor!: IPerson;

  postsPage = 1;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  POSTS_PAGE_LIMIT = POSTS_PAGE_LIMIT;

  get isCurrentActorMember(): boolean {
    if (!this.group || !this.memberships) return false;
    return this.memberships
      .map(({ parent: { id } }) => id)
      .includes(this.group.id);
  }
}
</script>
<style lang="scss" scoped>
.container.section {
  background: $white;
}

section {
  div.intro,
  .post-list {
    margin-bottom: 1rem;
  }
}
</style>
