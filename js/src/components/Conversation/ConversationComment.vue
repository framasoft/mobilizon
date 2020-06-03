<template>
  <article class="comment">
    <div class="avatar">
      <figure class="image is-48x48" v-if="comment.actor.avatar">
        <img class="is-rounded" :src="comment.actor.avatar.url" alt="" />
      </figure>
      <b-icon v-else size="is-medium" icon="account-circle" />
    </div>
    <div class="body">
      <div class="meta">
        <div class="name">
          <span>@{{ comment.actor.preferredUsername }}</span>
        </div>
        <div class="post-infos">
          <span>{{ comment.updatedAt | formatDateTimeString }}</span>
        </div>
      </div>
      <div class="description-content" v-html="comment.text"></div>
    </div>
  </article>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IComment } from "../../types/comment.model";

@Component
export default class ConversationComment extends Vue {
  @Prop({ required: true, type: Object }) comment!: IComment;
}
</script>
<style lang="scss" scoped>
@import "@/variables.scss";

article.comment {
  display: flex;
  border-top: 1px solid #e9e9e9;

  div.body {
    flex: 2;
    margin-bottom: 2rem;
    padding-top: 1rem;

    .meta {
      display: flex;
      align-items: center;
      padding: 0 1rem 0.3em;

      .name {
        margin-right: auto;
        flex: 1 1 auto;
        overflow: hidden;

        span {
          color: #3c376e;
        }
      }
    }

    div.description-content {
      padding: 0 1rem 0.3rem;

      /deep/ h1 {
        font-size: 2rem;
      }

      /deep/ h2 {
        font-size: 1.5rem;
      }

      /deep/ h3 {
        font-size: 1.25rem;
      }

      /deep/ ul {
        list-style-type: disc;
      }

      /deep/ li {
        margin: 10px auto 10px 2rem;
      }

      /deep/ blockquote {
        border-left: 0.2em solid #333;
        display: block;
        padding-left: 1em;
      }

      /deep/ p {
        margin: 10px auto;

        a {
          display: inline-block;
          padding: 0.3rem;
          background: $secondary;
          color: #111;

          &:empty {
            display: none;
          }
        }
      }
    }
  }

  div.avatar {
    padding-top: 1rem;
    flex: 0;
  }
}
</style>
