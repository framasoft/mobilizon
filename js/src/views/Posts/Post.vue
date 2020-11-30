<template>
  <div>
    <article class="container" v-if="post">
      <section class="heading-section">
        <h1 class="title">{{ post.title }}</h1>
        <i18n tag="span" path="By {author}" class="authors">
          <router-link
            slot="author"
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(post.attributedTo),
              },
            }"
            >{{ post.attributedTo.name }}</router-link
          >
        </i18n>
        <p class="published" v-if="!post.draft">
          {{ post.publishAt | formatDateTimeString }}
        </p>
        <small
          v-if="post.visibility === PostVisibility.PRIVATE"
          class="has-text-grey"
        >
          <b-icon icon="lock" size="is-small" />
          {{
            $t("Accessible only to members", { group: post.attributedTo.name })
          }}
        </small>
        <p class="buttons" v-if="isCurrentActorMember">
          <b-tag type="is-warning" size="is-medium" v-if="post.draft">{{
            $t("Draft")
          }}</b-tag>
          <router-link
            v-if="
              currentActor.id === post.author.id ||
              isCurrentActorAGroupModerator
            "
            :to="{ name: RouteName.POST_EDIT, params: { slug: post.slug } }"
            tag="button"
            class="button is-text"
            >{{ $t("Edit") }}</router-link
          >
        </p>
        <img v-if="post.picture" :src="post.picture.url" alt="" />
      </section>
      <section v-html="post.body" class="content" />
      <section class="tags">
        <router-link
          v-for="tag in post.tags"
          :key="tag.title"
          :to="{ name: RouteName.TAG, params: { tag: tag.title } }"
        >
          <tag>{{ tag.title }}</tag>
        </router-link>
      </section>
    </article>
  </div>
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";
import { PostVisibility } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "../../graphql/actor";
import { FETCH_POST } from "../../graphql/post";

import { IPost } from "../../types/post.model";
import { IPerson, usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import Tag from "../../components/Tag.vue";

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
    post: {
      query: FETCH_POST,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          slug: this.slug,
        };
      },
      skip() {
        return !this.slug;
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
  },
  components: {
    Tag,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.post ? this.post.title : "",
      // all titles will be injected into this template
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      titleTemplate: this.post ? "%s | Mobilizon" : "Mobilizon",
    };
  },
})
export default class Post extends mixins(GroupMixin) {
  @Prop({ required: true, type: String }) slug!: string;

  post!: IPost;

  memberships!: IMember[];

  currentActor!: IPerson;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  PostVisibility = PostVisibility;

  handleErrors(errors: any[]): void {
    if (errors.some((error) => error.status_code === 404)) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  get isCurrentActorMember(): boolean {
    if (!this.post.attributedTo || !this.memberships) return false;
    return this.memberships
      .map(({ parent: { id } }) => id)
      .includes(this.post.attributedTo.id);
  }
}
</script>
<style lang="scss" scoped>
article {
  section.heading-section {
    text-align: center;
    position: relative;
    display: flex;
    flex-direction: column;
    margin: auto -3rem 2rem;

    h1.title {
      margin: 0 auto;
      padding-top: 3rem;
      font-size: 3rem;
      font-weight: 700;
    }

    .authors {
      margin-top: 2rem;
      display: inline-block;
    }

    .published {
      margin-top: 1rem;
      color: rgba(0, 0, 0, 0.5);
    }

    &::after {
      height: 0.2rem;
      content: " ";
      display: block;
      width: 100%;
      background-color: $purple-1;
      margin-top: 1rem;
    }

    .buttons {
      justify-content: center;
    }
    & > * {
      z-index: 10;
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
      z-index: 0;
    }
  }

  section.content {
    font-size: 1.1rem;
  }

  section.tags {
    padding-bottom: 5rem;

    a {
      text-decoration: none;
    }
    span {
      &.tag {
        margin: 0 2px;
      }
    }
  }

  background: $white;
  max-width: 700px;
  margin: 0 auto;
  padding: 0 3rem;
}
</style>
