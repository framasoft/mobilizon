<template>
    <li :class="{ reply: comment.inReplyToComment }">
        <article class="media" :class="{ selected: commentSelected, organizer: commentFromOrganizer }" :id="commentId">
            <figure class="media-left" v-if="!comment.deletedAt && comment.actor.avatar">
                <p class="image is-48x48">
                    <img :src="comment.actor.avatar.url" alt="">
                </p>
            </figure>
            <b-icon class="media-left" v-else size="is-large" icon="account-circle" />
            <div class="media-content">
                <div class="content">
                    <span class="first-line" v-if="!comment.deletedAt">
                        <strong>{{ comment.actor.name }}</strong>
                        <small>@{{ comment.actor.preferredUsername }}</small>
                        <a class="comment-link has-text-grey" :href="commentId">
                            <small>{{ timeago(new Date(comment.updatedAt)) }}</small>
                        </a>
                    </span>
                    <a v-else class="comment-link has-text-grey" :href="commentId">
                        <span>{{ $t('[deleted]') }}</span>
                    </a>
                    <span class="icons" v-if="!comment.deletedAt">
                        <span v-if="comment.actor.id === currentActor.id"
                              @click="$emit('delete-comment', comment)">
                            <b-icon
                                icon="delete"
                                size="is-small"
                            />
                        </span>
                        <span @click="reportModal()">
                            <b-icon
                                    icon="alert"
                                    size="is-small"
                            />
                        </span>
                    </span>
                    <br>
                    <div v-if="!comment.deletedAt" v-html="comment.text" />
                    <div v-else>{{ $t('[This comment has been deleted]') }}</div>
                    <span class="load-replies" v-if="comment.totalReplies">
                        <span v-if="!showReplies" @click="fetchReplies">
                            {{ $tc('View a reply', comment.totalReplies, { totalReplies: comment.totalReplies }) }}
                        </span>
                        <span v-else-if="comment.totalReplies && showReplies" @click="showReplies = false">
                            {{ $t('Hide replies') }}
                        </span>
                    </span>
                </div>
                <nav class="reply-action level is-mobile" v-if="currentActor.id && event.options.commentModeration !== CommentModeration.CLOSED">
                    <div class="level-left">
                      <span style="cursor: pointer" class="level-item" @click="createReplyToComment(comment)">
                        <span class="icon is-small">
                          <b-icon icon="reply" />
                        </span>
                        {{ $t('Reply') }}
                      </span>
                    </div>
                </nav>
            </div>
        </article>
        <form class="reply" @submit.prevent="replyToComment" v-if="currentActor.id" v-show="replyTo">
            <article class="media reply">
                <figure class="media-left" v-if="currentActor.avatar">
                    <p class="image is-48x48">
                        <img :src="currentActor.avatar.url" alt="">
                    </p>
                </figure>
                <b-icon class="media-left" v-else size="is-large" icon="account-circle" />
                <div class="media-content">
                    <div class="content">
                        <span class="first-line">
                            <strong>{{ currentActor.name}}</strong>
                            <small>@{{ currentActor.preferredUsername }}</small>
                        </span>
                        <br>
                        <span class="editor-line">
                            <editor class="editor" ref="commenteditor" v-model="newComment.text" mode="comment" />
                            <b-button :disabled="newComment.text.trim().length === 0" native-type="submit" type="is-info">{{ $t('Post a reply') }}</b-button>
                        </span>
                    </div>
                </div>
            </article>
        </form>
        <transition-group name="comment-replies" v-if="showReplies" class="comment-replies" tag="ul">
            <comment
                    class="reply"
                    v-for="reply in comment.replies"
                    :key="reply.id"
                    :comment="reply"
                    :event="event"
                    @create-comment="$emit('create-comment', $event)"
                    @delete-comment="$emit('delete-comment', $event)" />
        </transition-group>
    </li>
</template>
<script lang="ts">
import { Component, Prop, Vue } from 'vue-property-decorator';
import { CommentModel, IComment } from '@/types/comment.model';
import { CURRENT_ACTOR_CLIENT } from '@/graphql/actor';
import { IPerson } from '@/types/actor';
import { Refs } from '@/shims-vue';
import EditorComponent from '@/components/Editor.vue';
import TimeAgo from 'javascript-time-ago';
import { COMMENTS_THREADS, FETCH_THREAD_REPLIES } from '@/graphql/comment';
import { IEvent, CommentModeration } from '@/types/event.model';
import ReportModal from '@/components/Report/ReportModal.vue';
import { IReport } from '@/types/report.model';
import { CREATE_REPORT } from '@/graphql/report';

@Component({
  apollo: {
    currentActor: {
      query: CURRENT_ACTOR_CLIENT,
    },
  },
  components: {
    editor: () => import(/* webpackChunkName: "editor" */ '@/components/Editor.vue'),
    Comment,
  },
})
export default class Comment extends Vue {
  @Prop({ required: true, type: Object }) comment!: IComment;
  @Prop({ required: true, type: Object }) event!: IEvent;

  $refs!: Refs<{
    commenteditor: EditorComponent,
  }>;

  currentActor!: IPerson;
  newComment: IComment = new CommentModel();
  replyTo: boolean = false;
  showReplies: boolean = false;
  timeAgoInstance = null;
  CommentModeration = CommentModeration;

  async mounted() {
    const localeName = this.$i18n.locale;
    const locale = await import(`javascript-time-ago/locale/${localeName}`);
    TimeAgo.addLocale(locale);
    this.timeAgoInstance = new TimeAgo(localeName);

    const hash = this.$route.hash;
    if (hash.includes(`#comment-${this.comment.uuid}`)) {
      this.fetchReplies();
    }
  }

  async createReplyToComment(comment: IComment) {
    if (this.replyTo) {
      this.replyTo = false;
      this.newComment = new CommentModel();
      return;
    }
    this.replyTo = true;
        // this.newComment.inReplyToComment = comment;
    await this.$nextTick();
    await this.$nextTick(); // For some reason commenteditor needs two $nextTick() to fully render
    const commentEditor = this.$refs.commenteditor;
    commentEditor.replyToComment(comment);
  }

  replyToComment() {
    this.newComment.inReplyToComment = this.comment;
    this.newComment.originComment = this.comment.originComment || this.comment;
    this.newComment.actor = this.currentActor;
    this.$emit('create-comment', this.newComment);
    this.newComment = new CommentModel();
    this.replyTo = false;
  }

  async fetchReplies() {
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
    const parentCommentIndex = comments.findIndex(oldComment => oldComment.id === parentId);
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

  timeago(dateTime): String {
    if (this.timeAgoInstance != null) {
            // @ts-ignore
      return this.timeAgoInstance.format(dateTime);
    }
    return '';
  }

  get commentSelected(): boolean {
    return this.commentId === this.$route.hash;
  }

  get commentFromOrganizer(): boolean {
    return this.event.organizerActor !== undefined && this.comment.actor.id === this.event.organizerActor.id;
  }

  get commentId(): String {
    if (this.comment.originComment) return `#comment-${this.comment.originComment.uuid}:${this.comment.uuid}`;
    return `#comment-${this.comment.uuid}`;
  }

  reportModal() {
    console.log('report modal');
    this.$buefy.modal.open({
      parent: this,
      component: ReportModal,
      props: {
        title: this.$t('Report this comment'),
        comment: this.comment,
        onConfirm: this.reportComment,
      },
    });
  }

  async reportComment(content: String, forward: boolean) {
    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          eventId: this.event.id,
          reporterId: this.currentActor.id,
          reportedId: this.comment.actor.id,
          commentsIds: [this.comment.id],
          content,
        },
      });
      this.$buefy.notification.open({
        message: this.$t('Comment from @{username} reported', { username: this.comment.actor.preferredUsername }) as string,
        type: 'is-success',
        position: 'is-bottom-right',
        duration: 5000,
      });
    } catch (error) {
      console.error(error);
    }
  }
}
</script>
<style lang="scss" scoped>
    @import "@/variables.scss";

    .first-line {
        * {
            padding: 0 5px 0 0;
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

    .root-comment .comment-replies > .reply {
        padding-left: 3rem;
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
        cursor: pointer;
    }

    .load-replies {
        cursor: pointer;
    }

    article {
        border-radius: 4px;

        &.selected {
            background-color: lighten($secondary, 30%);
        }
        &.organizer:not(.selected) {
            background-color: lighten($primary, 50%);
        }
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
</style>
