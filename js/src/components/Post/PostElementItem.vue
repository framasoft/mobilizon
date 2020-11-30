<template>
  <router-link
    class="post-minimalist-card-wrapper"
    :to="{ name: RouteName.POST, params: { slug: post.slug } }"
  >
    <div class="title-info-wrapper">
      <div class="media">
        <div class="media-left">
          <figure class="image is-96x96" v-if="post.picture">
            <img :src="post.picture.url" alt="" />
          </figure>
          <b-icon v-else size="is-large" icon="post" />
        </div>
        <div class="media-content">
          <p class="post-minimalist-title">{{ post.title }}</p>
          <div class="metadata">
            <b-tag type="is-warning" size="is-small" v-if="post.draft">{{
              $t("Draft")
            }}</b-tag>
            <small
              v-if="
                post.visibility === PostVisibility.PUBLIC &&
                isCurrentActorMember
              "
              class="has-text-grey"
            >
              <b-icon icon="earth" size="is-small" />{{ $t("Public") }}</small
            >
            <small
              v-else-if="post.visibility === PostVisibility.UNLISTED"
              class="has-text-grey"
            >
              <b-icon icon="link" size="is-small" />{{
                $t("Accessible through link")
              }}</small
            >
            <small
              v-else-if="post.visibility === PostVisibility.PRIVATE"
              class="has-text-grey"
            >
              <b-icon icon="lock" size="is-small" />{{
                $t("Accessible only to members", {
                  group: post.attributedTo.name,
                })
              }}</small
            >
            <small class="has-text-grey">{{
              $options.filters.formatDateTimeString(
                new Date(post.insertedAt),
                false
              )
            }}</small>
            <small class="has-text-grey" v-if="isCurrentActorMember">{{
              $t("Created by {username}", {
                username: `@${usernameWithDomain(post.author)}`,
              })
            }}</small>
          </div>
        </div>
      </div>
    </div>
  </router-link>
</template>
<script lang="ts">
import { usernameWithDomain } from "@/types/actor";
import { PostVisibility } from "@/types/enums";
import { Component, Prop, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { IPost } from "../../types/post.model";

@Component
export default class PostElementItem extends Vue {
  @Prop({ required: true, type: Object }) post!: IPost;

  @Prop({ required: false, type: Boolean, default: false })
  isCurrentActorMember!: boolean;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  PostVisibility = PostVisibility;
}
</script>
<style lang="scss" scoped>
.post-minimalist-card-wrapper {
  text-decoration: none;
  display: flex;
  width: 100%;
  color: initial;
  border-bottom: 1px solid #e9e9e9;
  align-items: center;

  .title-info-wrapper {
    flex: 2;

    .post-minimalist-title {
      color: #3c376e;
      font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial,
        serif;
      font-size: 1rem;
      font-weight: 700;
      overflow: hidden;
      display: -webkit-box;
      -webkit-box-orient: vertical;
      -webkit-line-clamp: 2;
    }

    .media .media-left {
      & > span.icon {
        height: 96px;
        width: 96px;
      }
      & > figure.image > img {
        object-fit: cover;
        height: 100%;
        object-position: center;
        width: 100%;
      }
    }

    .metadata {
      & > span.tag {
        margin-right: 5px;
      }
      & > small:not(:last-child):after {
        content: "·";
        padding: 0 5px;
      }
    }
  }
}
</style>
