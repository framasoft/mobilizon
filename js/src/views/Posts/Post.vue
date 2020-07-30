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
              params: { preferredUsername: usernameWithDomain(post.attributedTo) },
            }"
            >{{ post.attributedTo.name }}</router-link
          >
        </i18n>
        <p class="published" v-if="!post.draft">{{ post.publishAt | formatDateTimeString }}</p>
        <p class="buttons" v-if="isCurrentActorMember">
          <b-tag type="is-warning" size="is-medium" v-if="post.draft">{{ $t("Draft") }}</b-tag>
          <router-link
            :to="{ name: RouteName.POST_EDIT, params: { slug: post.slug } }"
            tag="button"
            class="button is-text"
            >{{ $t("Edit") }}</router-link
          >
        </p>
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
import { Component, Vue, Prop } from "vue-property-decorator";
import Editor from "@/components/Editor.vue";
import { GraphQLError } from "graphql";
import { CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS, FETCH_GROUP } from "../../graphql/actor";
import { TAGS } from "../../graphql/tags";
import { CONFIG } from "../../graphql/config";
import { FETCH_POST, CREATE_POST } from "../../graphql/post";

import { IPost, PostVisibility } from "../../types/post.model";
import { IGroup, IMember, usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import Tag from "../../components/Tag.vue";

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    memberships: {
      query: PERSON_MEMBERSHIPS,
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
      // eslint-disable-next-line @typescript-eslint/ban-ts-ignore
      // @ts-ignore
      title: this.post ? this.post.title : "",
      // all titles will be injected into this template
      // eslint-disable-next-line @typescript-eslint/ban-ts-ignore
      // @ts-ignore
      titleTemplate: this.post ? "%s | Mobilizon" : "Mobilizon",
    };
  },
})
export default class Post extends Vue {
  @Prop({ required: true, type: String }) slug!: string;

  post!: IPost;

  memberships!: IMember[];

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  get isCurrentActorMember(): boolean {
    if (!this.post.attributedTo || !this.memberships) return false;
    return this.memberships.map(({ parent: { id } }) => id).includes(this.post.attributedTo.id);
  }

  async handleErrors(errors: GraphQLError[]) {
    if (errors[0].message.includes("No such post")) {
      await this.$router.push({ name: RouteName.PAGE_NOT_FOUND });
    }
  }
}
</script>
<style lang="scss" scoped>
@import "../../variables.scss";

article {
  section.heading-section {
    text-align: center;

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
      height: 0.4rem;
      margin-bottom: 2rem;
      content: " ";
      display: block;
      width: 100%;
      background-color: $purple-1;
      margin-top: 1rem;
    }

    .buttons {
      justify-content: center;
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
