<template>
  <li :class="{ reply: comment.inReplyToComment }">
    <article
      class="media"
      :class="{ selected: commentSelected }"
      :id="commentId"
    >
      <popover-actor-card
        class="media-left"
        :actor="comment.actor"
        :inline="true"
        v-if="comment.actor"
      >
        <figure
          class="image is-48x48"
          v-if="!comment.deletedAt && comment.actor.avatar"
        >
          <img class="is-rounded" :src="comment.actor.avatar.url" alt="" />
        </figure>
        <b-icon
          class="media-left"
          v-else
          size="is-large"
          icon="account-circle"
        />
      </popover-actor-card>
      <div v-else class="media-left">
        <figure
          class="image is-48x48"
          v-if="!comment.deletedAt && comment.actor.avatar"
        >
          <img class="is-rounded" :src="comment.actor.avatar.url" alt="" />
        </figure>
        <b-icon v-else size="is-large" icon="account-circle" />
      </div>
      <div class="media-content">
        <div class="content">
          <span class="first-line" v-if="!comment.deletedAt">
            <strong :class="{ organizer: commentFromOrganizer }">{{
              comment.actor.name
            }}</strong>
            <small>@{{ usernameWithDomain(comment.actor) }}</small>
            <a class="comment-link has-text-grey" :href="commentURL">
              <small>{{
                formatDistanceToNow(new Date(comment.updatedAt), {
                  locale: $dateFnsLocale,
                  addSuffix: true,
                })
              }}</small>
            </a>
          </span>
          <a v-else class="comment-link has-text-grey" :href="commentURL">
            <span>{{ $t("[deleted]") }}</span>
          </a>
          <span class="icons" v-if="!comment.deletedAt">
            <button
              v-if="comment.actor.id === currentActor.id"
              @click="$emit('delete-comment', comment)"
            >
              <b-icon icon="delete" size="is-small" aria-hidden="true" />
              <span class="visually-hidden">{{ $t("Delete") }}</span>
            </button>
            <button @click="reportModal()">
              <b-icon icon="alert" size="is-small" />
              <span class="visually-hidden">{{ $t("Report") }}</span>
            </button>
          </span>
          <br />
          <div v-if="!comment.deletedAt" v-html="comment.text" />
          <div v-else>{{ $t("[This comment has been deleted]") }}</div>
          <div class="load-replies" v-if="comment.totalReplies">
            <p v-if="!showReplies" @click="fetchReplies">
              <b-icon icon="chevron-down" /><span>{{
                $tc("View a reply", comment.totalReplies, {
                  totalReplies: comment.totalReplies,
                })
              }}</span>
            </p>
            <p
              v-else-if="comment.totalReplies && showReplies"
              @click="showReplies = false"
            >
              <b-icon icon="chevron-up" />
              <span>{{ $t("Hide replies") }}</span>
            </p>
          </div>
        </div>
        <nav
          class="reply-action level is-mobile"
          v-if="
            currentActor.id &&
            event.options.commentModeration !== CommentModeration.CLOSED &&
            !comment.deletedAt
          "
        >
          <div class="level-left">
            <span
              style="cursor: pointer"
              class="level-item reply-btn"
              @click="createReplyToComment(comment)"
            >
              <span class="icon is-small">
                <b-icon icon="reply" />
              </span>
              <span>{{ $t("Reply") }}</span>
            </span>
          </div>
        </nav>
      </div>
    </article>
    <form
      class="reply"
      @submit.prevent="replyToComment"
      v-if="currentActor.id"
      v-show="replyTo"
    >
      <article class="media reply">
        <figure class="media-left" v-if="currentActor.avatar">
          <p class="image is-48x48">
            <img :src="currentActor.avatar.url" alt="" />
          </p>
        </figure>
        <b-icon
          class="media-left"
          v-else
          size="is-large"
          icon="account-circle"
        />
        <div class="media-content">
          <div class="content">
            <span class="first-line">
              <strong>{{ currentActor.name }}</strong>
              <small>@{{ currentActor.preferredUsername }}</small>
            </span>
            <br />
            <span class="editor-line">
              <editor
                class="editor"
                ref="commentEditor"
                v-model="newComment.text"
                mode="comment"
              />
              <b-button
                :disabled="newComment.text.trim().length === 0"
                native-type="submit"
                type="is-primary"
                >{{ $t("Post a reply") }}</b-button
              >
            </span>
          </div>
        </div>
      </article>
    </form>
    <div class="replies">
      <div class="left">
        <div class="vertical-border" @click="showReplies = false" />
      </div>
      <transition-group
        name="comment-replies"
        v-if="showReplies"
        class="comment-replies"
        tag="ul"
      >
        <comment
          class="reply"
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :event="event"
          @create-comment="$emit('create-comment', $event)"
          @delete-comment="$emit('delete-comment', $event)"
        />
      </transition-group>
    </div>
  </li>
</template>
<script lang="ts">
import { Component, Prop, Vue, Ref } from "vue-property-decorator";
import EditorComponent from "@/components/Editor.vue";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { formatDistanceToNow } from "date-fns";
import { CommentModeration } from "@/types/enums";
import { CommentModel, IComment } from "../../types/comment.model";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IPerson, usernameWithDomain } from "../../types/actor";
import { COMMENTS_THREADS, FETCH_THREAD_REPLIES } from "../../graphql/comment";
import { IEvent } from "../../types/event.model";
import ReportModal from "../Report/ReportModal.vue";
import { IReport } from "../../types/report.model";
import { CREATE_REPORT } from "../../graphql/report";
import PopoverActorCard from "../Account/PopoverActorCard.vue";

@Component({
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
  components: {
    editor: () =>
      import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
    comment: () => import(/* webpackChunkName: "comment" */ "./Comment.vue"),
    PopoverActorCard,
  },
})
export default class Comment extends Vue {
  @Prop({ required: true, type: Object }) comment!: IComment;

  @Prop({ required: true, type: Object }) event!: IEvent;

  // Hack because Vue only exports it's own interface.
  // See https://github.com/kaorun343/vue-property-decorator/issues/257
  @Ref() readonly commentEditor!: EditorComponent & {
    replyToComment: (comment: IComment) => void;
  };

  currentActor!: IPerson;

  newComment: IComment = new CommentModel();

  replyTo = false;

  showReplies = false;

  CommentModeration = CommentModeration;

  usernameWithDomain = usernameWithDomain;

  formatDistanceToNow = formatDistanceToNow;

  async mounted(): Promise<void> {
    const { hash } = this.$route;
    if (hash.includes(`#comment-${this.comment.uuid}`)) {
      this.fetchReplies();
    }
  }

  async createReplyToComment(comment: IComment): Promise<void> {
    if (this.replyTo) {
      this.replyTo = false;
      this.newComment = new CommentModel();
      return;
    }
    this.replyTo = true;
    // this.newComment.inReplyToComment = comment;
    await this.$nextTick();
    await this.$nextTick(); // For some reason commenteditor needs two $nextTick() to fully render
    this.commentEditor.replyToComment(comment);
  }

  replyToComment(): void {
    this.newComment.inReplyToComment = this.comment;
    this.newComment.originComment = this.comment.originComment || this.comment;
    this.newComment.actor = this.currentActor;
    this.$emit("create-comment", this.newComment);
    this.newComment = new CommentModel();
    this.replyTo = false;
  }

  async fetchReplies(): Promise<void> {
    const parentId = this.comment.id;
    const { data } = await this.$apollo.query<{ thread: IComment[] }>({
      query: FETCH_THREAD_REPLIES,
      variables: {
        threadId: parentId,
      },
    });
    if (!data) return;
    const { thread } = data;
    const eventData = this.$apollo.getClient().readQuery<{ event: IEvent }>({
      query: COMMENTS_THREADS,
      variables: {
        eventUUID: this.event.uuid,
      },
    });
    if (!eventData) return;
    const { event } = eventData;
    const { comments } = event;
    const parentCommentIndex = comments.findIndex(
      (oldComment) => oldComment.id === parentId
    );
    const parentComment = comments[parentCommentIndex];
    if (!parentComment) return;
    parentComment.replies = thread;
    comments[parentCommentIndex] = parentComment;
    event.comments = comments;
    this.$apollo.getClient().writeQuery({
      query: COMMENTS_THREADS,
      data: { event },
    });
    this.showReplies = true;
  }

  get commentSelected(): boolean {
    return this.commentId === this.$route.hash;
  }

  get commentFromOrganizer(): boolean {
    return (
      this.event.organizerActor !== undefined &&
      this.comment.actor != null &&
      this.comment.actor.id === this.event.organizerActor.id
    );
  }

  get commentId(): string {
    if (this.comment.originComment)
      return `#comment-${this.comment.originComment.uuid}:${this.comment.uuid}`;
    return `#comment-${this.comment.uuid}`;
  }

  get commentURL(): string {
    if (!this.comment.local && this.comment.url) return this.comment.url;
    return this.commentId;
  }

  reportModal(): void {
    if (!this.comment.actor) return;
    this.$buefy.modal.open({
      parent: this,
      component: ReportModal,
      props: {
        title: this.$t("Report this comment"),
        comment: this.comment,
        onConfirm: this.reportComment,
        outsideDomain: this.comment.actor.domain,
      },
    });
  }

  async reportComment(content: string, forward: boolean): Promise<void> {
    try {
      if (!this.comment.actor) return;
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          eventId: this.event.id,
          reportedId: this.comment.actor.id,
          commentsIds: [this.comment.id],
          content,
          forward,
        },
      });
      this.$buefy.notification.open({
        message: this.$t("Comment from @{username} reported", {
          username: this.comment.actor.preferredUsername,
        }) as string,
        type: "is-success",
        position: "is-bottom-right",
        duration: 5000,
      });
    } catch (e) {
      Snackbar.open({
        message: e.message,
        type: "is-danger",
        position: "is-bottom",
      });
    }
  }
}
</script>
<style lang="scss" scoped>
form.reply {
  padding-bottom: 1rem;
}

.first-line {
  margin-bottom: 3px;

  * {
    padding: 0 5px 0 0;
  }

  strong.organizer {
    background: $background-color;
    border-radius: 12px;
    color: white;
    padding: 0 6px;
  }

  & > small {
    margin-left: 0.3rem;
  }
}

.editor-line {
  display: flex;
  max-width: calc(80rem - 64px);

  .editor {
    flex: 1;
    padding-right: 10px;
    margin-bottom: 0;
  }
}

.comment-link small:hover {
  color: hsl(0, 0%, 21%);
}

.root-comment .replies {
  display: flex;

  .left {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-right: 10px;

    .vertical-border {
      width: 3px;
      height: 100%;
      background-color: rgba(0, 0, 0, 0.05);
      margin: 10px calc(1rem + 1px);
      cursor: pointer;

      &:hover {
        background-color: rgba(0, 0, 0, 0.1);
      }
    }
  }
}

.media .media-content {
  .content .editor-line {
    display: flex;
    align-items: center;
  }

  .icons {
    display: none;
  }
}

.media:hover .media-content .icons {
  display: inline;

  button {
    cursor: pointer;
    border: none;
    background: none;
  }
}

.load-replies {
  cursor: pointer;

  & > p > span {
    font-weight: bold;
    color: $primary;
  }
}

.level-item.reply-btn {
  font-weight: bold;
  color: $primary;
}

article {
  border-radius: 4px;
  margin-bottom: 5px;

  &.selected {
    background-color: lighten($secondary, 30%);
  }
}

.comment-replies {
  flex-grow: 1;
}

.comment-replies-enter-active,
.comment-replies-leave-active,
.comment-replies-move {
  transition: 500ms cubic-bezier(0.59, 0.12, 0.34, 0.95);
  transition-property: opacity, transform;
}

.comment-replies-enter {
  opacity: 0;
  transform: translateX(50px) scaleY(0.5);
}

.comment-replies-enter-to {
  opacity: 1;
  transform: translateX(0) scaleY(1);
}

.comment-replies-leave-active {
  position: absolute;
}

.comment-replies-leave-to {
  opacity: 0;
  transform: scaleY(0);
  transform-origin: center top;
}

.reply-action .icon {
  padding-right: 0.4rem;
}

.visually-hidden {
  display: none;
}
</style>
