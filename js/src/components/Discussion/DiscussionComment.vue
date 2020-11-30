<template>
  <article class="comment">
    <div class="avatar">
      <figure class="image is-48x48" v-if="comment.actor.avatar">
        <img class="is-rounded" :src="comment.actor.avatar.url" alt="" />
      </figure>
      <b-icon v-else size="is-large" icon="account-circle" />
    </div>
    <div class="body">
      <div class="meta">
        <span class="first-line name" v-if="!comment.deletedAt">
          <strong>{{ comment.actor.name }}</strong>
          <small>@{{ usernameWithDomain(comment.actor) }}</small>
        </span>
        <span v-else class="name comment-link has-text-grey">
          {{ $t("[deleted]") }}
        </span>
        <span
          class="icons"
          v-if="!comment.deletedAt && comment.actor.id === currentActor.id"
        >
          <b-dropdown aria-role="list">
            <b-icon slot="trigger" role="button" icon="dots-horizontal" />

            <b-dropdown-item
              v-if="comment.actor.id === currentActor.id"
              @click="toggleEditMode"
              aria-role="menuitem"
            >
              <b-icon icon="pencil"></b-icon>
              {{ $t("Edit") }}
            </b-dropdown-item>
            <b-dropdown-item
              v-if="comment.actor.id === currentActor.id"
              @click="$emit('delete-comment', comment)"
              aria-role="menuitem"
            >
              <b-icon icon="delete"></b-icon>
              {{ $t("Delete") }}
            </b-dropdown-item>
            <!-- <b-dropdown-item aria-role="listitem" @click="isReportModalActive = true">
              <b-icon icon="flag" />
              {{ $t("Report") }}
            </b-dropdown-item> -->
          </b-dropdown>
        </span>
        <div class="post-infos">
          <span :title="comment.insertedAt | formatDateTimeString">
            {{
              formatDistanceToNow(new Date(comment.updatedAt), {
                locale: $dateFnsLocale,
              }) || $t("Right now")
            }}</span
          >
        </div>
      </div>
      <div v-if="!editMode && !comment.deletedAt" class="text-wrapper">
        <div class="description-content" v-html="comment.text"></div>
        <p
          v-if="comment.insertedAt.getTime() !== comment.updatedAt.getTime()"
          :title="comment.updatedAt | formatDateTimeString"
        >
          {{
            $t("Edited {ago}", {
              ago: formatDistanceToNow(new Date(comment.updatedAt), {
                locale: $dateFnsLocale,
              }),
            })
          }}
        </p>
      </div>
      <div class="comment-deleted" v-else-if="!editMode">
        {{ $t("[This comment has been deleted by it's author]") }}
      </div>
      <form v-else class="edition" @submit.prevent="updateComment">
        <editor v-model="updatedComment" />
        <div class="buttons">
          <b-button
            native-type="submit"
            :disabled="['<p></p>', '', comment.text].includes(updatedComment)"
            type="is-primary"
            >{{ $t("Update") }}</b-button
          >
          <b-button native-type="button" @click="toggleEditMode">{{
            $t("Cancel")
          }}</b-button>
        </div>
      </form>
    </div>
  </article>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { formatDistanceToNow } from "date-fns";
import { IComment } from "../../types/comment.model";
import { usernameWithDomain, IPerson } from "../../types/actor";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";

@Component({
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
  },
  components: {
    editor: () =>
      import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
  },
})
export default class DiscussionComment extends Vue {
  @Prop({ required: true, type: Object }) comment!: IComment;

  editMode = false;

  updatedComment = "";

  currentActor!: IPerson;

  usernameWithDomain = usernameWithDomain;

  formatDistanceToNow = formatDistanceToNow;

  // isReportModalActive: boolean = false;

  toggleEditMode(): void {
    this.updatedComment = this.comment.text;
    this.editMode = !this.editMode;
  }

  updateComment(): void {
    this.comment.text = this.updatedComment;
    this.$emit("update-comment", this.comment);
    this.toggleEditMode();
  }
}
</script>
<style lang="scss" scoped>
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

        strong {
          display: block;
          line-height: 1rem;
        }

        color: #3c376e;
      }

      .icons {
        display: inline;
        cursor: pointer;
      }
    }

    .text-wrapper,
    .comment-deleted {
      padding: 0 1rem;

      & > p {
        font-size: 0.85rem;
        font-style: italic;
      }

      div.description-content {
        padding-bottom: 0.3rem;

        ::v-deep h1 {
          font-size: 2rem;
        }

        ::v-deep h2 {
          font-size: 1.5rem;
        }

        ::v-deep h3 {
          font-size: 1.25rem;
        }

        ::v-deep ul {
          list-style-type: disc;
        }

        ::v-deep li {
          margin: 10px auto 10px 2rem;
        }

        ::v-deep blockquote {
          border-left: 0.2em solid #333;
          display: block;
          padding-left: 1em;
        }

        ::v-deep p {
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
  }

  div.avatar {
    padding-top: 1rem;
    flex: 0;
  }

  .edition {
    .button {
      margin-top: 0.75rem;
    }
  }
}
</style>
