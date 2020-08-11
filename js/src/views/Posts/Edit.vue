<template>
  <form @submit.prevent="publish(false)">
    <div class="container section">
      <h1 class="title" v-if="isUpdate === true">
        {{ $t("Edit post") }}
      </h1>
      <h1 class="title" v-else>
        {{ $t("Add a new post") }}
      </h1>
      <subtitle>{{ $t("General information") }}</subtitle>
      <picture-upload v-model="pictureFile" :textFallback="$t('Headline picture')" />

      <b-field :label="$t('Title')">
        <b-input size="is-large" aria-required="true" required v-model="post.title" />
      </b-field>

      <tag-input v-model="post.tags" :data="tags" path="title" />

      <div class="field">
        <label class="label">{{ $t("Post") }}</label>
        <editor v-model="post.body" />
      </div>
      <subtitle>{{ $t("Who can view this post") }}</subtitle>
      <div class="field">
        <b-radio
          v-model="post.visibility"
          name="postVisibility"
          :native-value="PostVisibility.PUBLIC"
          >{{ $t("Visible everywhere on the web") }}</b-radio
        >
      </div>
      <div class="field">
        <b-radio
          v-model="post.visibility"
          name="postVisibility"
          :native-value="PostVisibility.UNLISTED"
          >{{ $t("Only accessible through link") }}</b-radio
        >
      </div>
      <div class="field">
        <b-radio
          v-model="post.visibility"
          name="postVisibility"
          :native-value="PostVisibility.PRIVATE"
          >{{ $t("Only accessible to members of the group") }}</b-radio
        >
      </div>
    </div>
    <nav class="navbar">
      <div class="container">
        <div class="navbar-menu">
          <div class="navbar-end">
            <span class="navbar-item">
              <b-button type="is-text" @click="$router.go(-1)">{{ $t("Cancel") }}</b-button>
            </span>
            <span class="navbar-item" v-if="this.isUpdate">
              <b-button type="is-danger is-outlined" @click="deletePost">{{
                $t("Delete post")
              }}</b-button>
            </span>
            <!-- If an post has been published we can't make it draft anymore -->
            <span class="navbar-item" v-if="post.draft === true">
              <b-button type="is-primary" outlined @click="publish(true)">{{
                $t("Save draft")
              }}</b-button>
            </span>
            <span class="navbar-item">
              <b-button type="is-primary" native-type="submit">
                <span v-if="isUpdate === false || post.draft === true">{{ $t("Publish") }}</span>

                <span v-else>{{ $t("Update post") }}</span>
              </b-button>
            </span>
          </div>
        </div>
      </div>
    </nav>
  </form>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { CURRENT_ACTOR_CLIENT, FETCH_GROUP } from "../../graphql/actor";
import { TAGS } from "../../graphql/tags";
import { CONFIG } from "../../graphql/config";
import { FETCH_POST, CREATE_POST, UPDATE_POST, DELETE_POST } from "../../graphql/post";

import { IPost, PostVisibility } from "../../types/post.model";
import Editor from "../../components/Editor.vue";
import { IGroup } from "../../types/actor";
import TagInput from "../../components/Event/TagInput.vue";
import RouteName from "../../router/name";

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    tags: TAGS,
    config: CONFIG,
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
    },
    group: {
      query: FETCH_GROUP,
      variables() {
        return {
          name: this.preferredUsername,
        };
      },
      skip() {
        return !this.preferredUsername;
      },
    },
  },
  components: {
    Editor,
    TagInput,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-ignore
      // @ts-ignore
      title: this.isUpdate
        ? (this.$t("Edit post") as string)
        : (this.$t("Add a new post") as string),
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class EditPost extends Vue {
  @Prop({ required: false, type: String }) slug: undefined | string;

  @Prop({ required: false, type: String }) preferredUsername!: string;

  @Prop({ type: Boolean, default: false }) isUpdate!: boolean;

  post: IPost = {
    title: "",
    body: "",
    local: true,
    draft: true,
    visibility: PostVisibility.PUBLIC,
    tags: [],
  };

  group!: IGroup;

  PostVisibility = PostVisibility;

  async publish(draft: boolean) {
    if (this.isUpdate) {
      const { data } = await this.$apollo.mutate({
        mutation: UPDATE_POST,
        variables: {
          id: this.post.id,
          title: this.post.title,
          body: this.post.body,
          tags: (this.post.tags || []).map(({ title }) => title),
          visibility: this.post.visibility,
          draft,
        },
      });
      if (data && data.updatePost) {
        return this.$router.push({ name: RouteName.POST, params: { slug: data.updatePost.slug } });
      }
    } else {
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_POST,
        variables: {
          ...this.post,
          tags: (this.post.tags || []).map(({ title }) => title),
          attributedToId: this.group.id,
          draft,
        },
      });
      if (data && data.createPost) {
        return this.$router.push({ name: RouteName.POST, params: { slug: data.createPost.slug } });
      }
    }
  }

  async deletePost() {
    const { data } = await this.$apollo.mutate({
      mutation: DELETE_POST,
      variables: {
        id: this.post.id,
      },
    });
    if (data && this.post.attributedTo) {
      return this.$router.push({
        name: RouteName.POSTS,
        params: { preferredUsername: this.post.attributedTo.preferredUsername },
      });
    }
  }
}
</script>
<style lang="scss" scoped>
form {
  nav.navbar {
    position: sticky;
    bottom: 0;
    min-height: 2rem;

    .container {
      min-height: 2rem;
    }
  }
}
</style>
