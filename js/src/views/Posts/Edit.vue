<template>
  <div>
    <form @submit.prevent="publish(false)" v-if="isCurrentActorAGroupModerator">
      <div class="container section">
        <h1 class="title" v-if="isUpdate === true">
          {{ $t("Edit post") }}
        </h1>
        <h1 class="title" v-else>
          {{ $t("Add a new post") }}
        </h1>
        <subtitle>{{ $t("General information") }}</subtitle>
        <picture-upload
          v-model="pictureFile"
          :textFallback="$t('Headline picture')"
          :defaultImage="post.picture"
        />

        <b-field
          :label="$t('Title')"
          :type="errors.title ? 'is-danger' : null"
          :message="errors.title"
        >
          <b-input
            size="is-large"
            aria-required="true"
            required
            v-model="post.title"
          />
        </b-field>

        <tag-input v-model="post.tags" :data="tags" path="title" />

        <div class="field">
          <label class="label">{{ $t("Post") }}</label>
          <p v-if="errors.body" class="help is-danger">{{ errors.body }}</p>
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
                <b-button type="is-text" @click="$router.go(-1)">{{
                  $t("Cancel")
                }}</b-button>
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
                  <span v-if="isUpdate === false || post.draft === true">{{
                    $t("Publish")
                  }}</span>

                  <span v-else>{{ $t("Update post") }}</span>
                </b-button>
              </span>
            </div>
          </div>
        </div>
      </nav>
    </form>
    <b-loading
      v-else-if="$apollo.loading"
      :is-full-page="false"
      :active.sync="$apollo.loading"
      :can-cancel="false"
    ></b-loading>
    <div class="container section" v-else>
      <b-message type="is-danger">
        {{ $t("Only group moderators can create, edit and delete posts.") }}
      </b-message>
    </div>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Watch } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import { FETCH_GROUP } from "@/graphql/group";
import {
  buildFileFromIMedia,
  buildFileVariable,
  readFileAsync,
} from "@/utils/image";
import GroupMixin from "@/mixins/group";
import { PostVisibility } from "@/types/enums";
import { TAGS } from "../../graphql/tags";
import { CONFIG } from "../../graphql/config";
import {
  FETCH_POST,
  CREATE_POST,
  UPDATE_POST,
  DELETE_POST,
} from "../../graphql/post";

import { IPost } from "../../types/post.model";
import Editor from "../../components/Editor.vue";
import { IActor, IGroup, usernameWithDomain } from "../../types/actor";
import TagInput from "../../components/Event/TagInput.vue";
import RouteName from "../../router/name";
import Subtitle from "../../components/Utils/Subtitle.vue";
import PictureUpload from "../../components/PictureUpload.vue";

@Component({
  apollo: {
    tags: TAGS,
    config: CONFIG,
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
    Subtitle,
    PictureUpload,
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.isUpdate
        ? (this.$t("Edit post") as string)
        : (this.$t("Add a new post") as string),
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class EditPost extends mixins(GroupMixin) {
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

  pictureFile: File | null = null;

  errors: Record<string, unknown> = {};

  async mounted(): Promise<void> {
    this.pictureFile = await buildFileFromIMedia(this.post.picture);
  }

  @Watch("post")
  async updatePostPicture(oldPost: IPost, newPost: IPost): Promise<void> {
    if (oldPost.picture !== newPost.picture) {
      this.pictureFile = await buildFileFromIMedia(this.post.picture);
    }
  }

  // eslint-disable-next-line consistent-return
  async publish(draft: boolean): Promise<void> {
    this.errors = {};

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
          ...(await this.buildPicture()),
        },
      });
      if (data && data.updatePost) {
        this.$router.push({
          name: RouteName.POST,
          params: { slug: data.updatePost.slug },
        });
      }
    } else {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: CREATE_POST,
          variables: {
            ...this.post,
            ...(await this.buildPicture()),
            tags: (this.post.tags || []).map(({ title }) => title),
            attributedToId: this.actualGroup.id,
            draft,
          },
        });
        if (data && data.createPost) {
          this.$router.push({
            name: RouteName.POST,
            params: { slug: data.createPost.slug },
          });
        }
      } catch (error) {
        console.error(error);
        this.errors = error.graphQLErrors.reduce(
          (acc: { [key: string]: any }, localError: any) => {
            acc[localError.field] = EditPost.transformMessage(
              localError.message
            );
            return acc;
          },
          {}
        );
      }
    }
  }

  async deletePost(): Promise<void> {
    const { data } = await this.$apollo.mutate({
      mutation: DELETE_POST,
      variables: {
        id: this.post.id,
      },
    });
    if (data && this.post.attributedTo) {
      this.$router.push({
        name: RouteName.POSTS,
        params: {
          preferredUsername: usernameWithDomain(this.post.attributedTo),
        },
      });
    }
  }

  static transformMessage(message: string[] | string): string | undefined {
    if (Array.isArray(message) && message.length > 0) {
      return message[0];
    }
    if (typeof message === "string") {
      return message;
    }
    return undefined;
  }

  async buildPicture(): Promise<Record<string, unknown>> {
    let obj: { picture?: any } = {};
    if (this.pictureFile) {
      const pictureObj = buildFileVariable(this.pictureFile, "picture");
      obj = { ...obj, ...pictureObj };
    }
    try {
      if (this.post.picture && this.pictureFile) {
        const oldPictureFile = (await buildFileFromIMedia(
          this.post.picture
        )) as File;
        const oldPictureFileContent = await readFileAsync(oldPictureFile);
        const newPictureFileContent = await readFileAsync(
          this.pictureFile as File
        );
        if (oldPictureFileContent === newPictureFileContent) {
          obj.picture = { mediaId: this.post.picture.id };
        }
      }
    } catch (e) {
      console.error(e);
    }
    return obj;
  }

  get actualGroup(): IActor {
    if (!this.group.id) {
      return this.post.attributedTo as IActor;
    }
    return this.group;
  }

  hasCurrentActorThisRole(givenRole: string | string[]): boolean {
    const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
    return (
      this.person &&
      this.actualGroup &&
      this.person.memberships.elements.some(
        ({ parent: { id }, role }) =>
          id === this.actualGroup.id && roles.includes(role)
      )
    );
  }
}
</script>
<style lang="scss" scoped>
.container.section {
  background: $white;
}
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
