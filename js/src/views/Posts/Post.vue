<template>
  <article class="container post" v-if="post">
    <header>
      <div class="banner-container">
        <lazy-image-wrapper :picture="post.picture" />
      </div>
      <div class="heading-section">
        <div class="heading-wrapper">
          <div class="title-metadata">
            <div class="title-wrapper">
              <b-tag
                class="mr-2"
                type="is-warning"
                size="is-medium"
                v-if="post.draft"
                >{{ $t("Draft") }}</b-tag
              >
              <h1 class="title">{{ post.title }}</h1>
            </div>
            <p class="metadata">
              <router-link
                slot="author"
                :to="{
                  name: RouteName.GROUP,
                  params: {
                    preferredUsername: usernameWithDomain(post.attributedTo),
                  },
                }"
              >
                <actor-inline :actor="post.attributedTo" />
              </router-link>
              <span class="published has-text-grey-dark" v-if="!post.draft">
                <b-icon icon="clock" size="is-small" />
                {{ post.publishAt | formatDateTimeString }}
              </span>
              <span
                class="published has-text-grey-dark"
                :title="
                  $options.filters.formatDateTimeString(
                    post.updatedAt,
                    undefined,
                    true,
                    'short'
                  )
                "
                v-else
              >
                <b-icon icon="clock" size="is-small" />
                {{
                  $t("Edited {relative_time} ago", {
                    relative_time: formatDistanceToNowStrict(
                      new Date(post.updatedAt),
                      {
                        locale: $dateFnsLocale,
                      }
                    ),
                  })
                }}
              </span>
              <span
                v-if="post.visibility === PostVisibility.UNLISTED"
                class="has-text-grey-dark"
              >
                <b-icon icon="link" size="is-small" />
                {{ $t("Accessible only by link") }}
              </span>
              <span
                v-else-if="post.visibility === PostVisibility.PRIVATE"
                class="has-text-grey-dark"
              >
                <b-icon icon="lock" size="is-small" />
                {{
                  $t("Accessible only to members", {
                    group: post.attributedTo.name,
                  })
                }}
              </span>
            </p>
          </div>
          <b-dropdown position="is-bottom-left" aria-role="list">
            <b-button slot="trigger" role="button" icon-right="dots-horizontal">
              {{ $t("Actions") }}
            </b-button>
            <b-dropdown-item
              aria-role="listitem"
              has-link
              v-if="
                currentActor.id === post.author.id ||
                isCurrentActorAGroupModerator
              "
            >
              <router-link
                :to="{
                  name: RouteName.POST_EDIT,
                  params: { slug: post.slug },
                }"
                >{{ $t("Edit") }} <b-icon icon="pencil"
              /></router-link>
            </b-dropdown-item>
            <b-dropdown-item
              aria-role="listitem"
              v-if="
                currentActor.id === post.author.id ||
                isCurrentActorAGroupModerator
              "
              @click="openDeletePostModal"
              @keyup.enter="openDeletePostModal"
            >
              {{ $t("Delete") }}
              <b-icon icon="delete" />
            </b-dropdown-item>

            <hr
              role="presentation"
              class="dropdown-divider"
              aria-role="menuitem"
              v-if="
                currentActor.id === post.author.id ||
                isCurrentActorAGroupModerator
              "
            />
            <b-dropdown-item
              aria-role="listitem"
              v-if="!post.draft"
              @click="triggerShare()"
              @keyup.enter="triggerShare()"
            >
              <span>
                {{ $t("Share this event") }}
                <b-icon icon="share" />
              </span>
            </b-dropdown-item>

            <b-dropdown-item
              aria-role="listitem"
              v-if="ableToReport"
              @click="isReportModalActive = true"
              @keyup.enter="isReportModalActive = true"
            >
              <span>
                {{ $t("Report") }}
                <b-icon icon="flag" />
              </span>
            </b-dropdown-item>
          </b-dropdown>
        </div>
      </div>
    </header>
    <b-message
      :title="$t('Members-only post')"
      class="mx-4"
      type="is-warning"
      :closable="false"
      v-if="
        !$apollo.loading &&
        isInstanceModerator &&
        !isCurrentActorAGroupMember &&
        post.visibility === PostVisibility.PRIVATE
      "
    >
      {{
        $t(
          "This post is accessible only for members. You have access to it for moderation purposes only because you are an instance moderator."
        )
      }}
    </b-message>

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
    <b-modal
      :active.sync="isReportModalActive"
      has-modal-card
      ref="reportModal"
    >
      <report-modal
        :on-confirm="reportPost"
        :title="$t('Report this post')"
        :outside-domain="groupDomain"
        @close="$refs.reportModal.close()"
      />
    </b-modal>
    <b-modal :active.sync="isShareModalActive" has-modal-card ref="shareModal">
      <share-post-modal :post="post" />
    </b-modal>
  </article>
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";
import { ICurrentUserRole, PostVisibility } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import {
  CURRENT_ACTOR_CLIENT,
  PERSON_MEMBERSHIPS,
  PERSON_STATUS_GROUP,
} from "../../graphql/actor";
import { usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import Tag from "../../components/Tag.vue";
import LazyImageWrapper from "../../components/Image/LazyImageWrapper.vue";
import ActorInline from "../../components/Account/ActorInline.vue";
import { formatDistanceToNowStrict } from "date-fns";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import SharePostModal from "../../components/Post/SharePostModal.vue";
import { IReport } from "@/types/report.model";
import { CREATE_REPORT } from "@/graphql/report";
import ReportModal from "../../components/Report/ReportModal.vue";
import PostMixin from "../../mixins/post";

@Component({
  apollo: {
    config: CONFIG,
    currentUser: CURRENT_USER_CLIENT,
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
    person: {
      query: PERSON_STATUS_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
          group: usernameWithDomain(this.post.attributedTo),
        };
      },
      skip() {
        return (
          !this.currentActor ||
          !this.currentActor.id ||
          !this.post?.attributedTo
        );
      },
    },
  },
  components: {
    Tag,
    LazyImageWrapper,
    ActorInline,
    SharePostModal,
    ReportModal,
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
export default class Post extends mixins(GroupMixin, PostMixin) {
  @Prop({ required: true, type: String }) slug!: string;

  memberships!: IMember[];

  config!: IConfig;

  RouteName = RouteName;

  currentUser!: ICurrentUser;

  usernameWithDomain = usernameWithDomain;

  formatDistanceToNowStrict = formatDistanceToNowStrict;

  PostVisibility = PostVisibility;

  isShareModalActive = false;

  isReportModalActive = false;

  get isCurrentActorMember(): boolean {
    if (!this.post.attributedTo || !this.memberships) return false;
    return this.memberships
      .map(({ parent: { id } }) => id)
      .includes(this.post.attributedTo.id);
  }

  get isInstanceModerator(): boolean {
    return [
      ICurrentUserRole.ADMINISTRATOR,
      ICurrentUserRole.MODERATOR,
    ].includes(this.currentUser.role);
  }

  get ableToReport(): boolean {
    return (
      this.config &&
      (this.currentActor.id != null || this.config.anonymous.reports.allowed)
    );
  }

  triggerShare(): void {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-start
    if (navigator.share) {
      navigator
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        .share({
          title: this.post.title,
          url: this.post.url,
        })
        .then(() => console.log("Successful share"))
        .catch((error: any) => console.log("Error sharing", error));
    } else {
      this.isShareModalActive = true;
      // send popup
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-end
  }

  async reportPost(content: string, forward: boolean): Promise<void> {
    this.isReportModalActive = false;
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.$refs.reportModal.close();
    const postTitle = this.post.title;

    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          postId: this.post.id,
          reportedId: this.post.attributedTo?.id,
          content,
          forward,
        },
      });
      this.$notifier.success(
        this.$t("Post {eventTitle} reported", { postTitle }) as string
      );
    } catch (error) {
      console.error(error);
    }
  }
  get groupDomain(): string | undefined | null {
    return this.post.attributedTo?.domain;
  }
}
</script>
<style lang="scss" scoped>
article.post {
  background: $white !important;
  header {
    display: flex;
    flex-direction: column;
    .banner-container {
      display: flex;
      justify-content: center;
      height: 30vh;
    }

    .heading-section {
      position: relative;
      display: flex;
      flex-direction: column;
      margin-bottom: 2rem;

      .heading-wrapper {
        padding: 15px 10px;
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        align-items: center;

        .title-metadata {
          min-width: 300px;
          flex: 20;

          .title-wrapper {
            display: inline;

            .tag {
              height: 38px;
              vertical-align: text-bottom;
            }

            & > h1 {
              display: inline;
            }
          }

          p.metadata {
            margin-top: 10px;
            display: flex;
            justify-content: flex-start;
            flex-wrap: wrap;
            flex-direction: column;

            *:not(:first-child) {
              padding-left: 5px;
            }
          }
        }
        p.buttons {
          flex: 1;
        }
      }

      h1.title {
        margin: 0;
        font-weight: 500;
        font-size: 38px;
        font-family: "Roboto", "Helvetica", "Arial", serif;
      }

      .authors {
        display: inline-block;
      }

      &::after {
        height: 0.2rem;
        content: " ";
        display: block;
        background-color: $purple-1;
      }

      .buttons {
        justify-content: center;
      }
    }
  }

  & > section {
    margin: 0 2rem;

    &.content {
      font-size: 1.1rem;
    }

    &.tags {
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
  }

  margin: 0 auto;

  a.dropdown-item,
  .dropdown .dropdown-menu .has-link a,
  button.dropdown-item {
    white-space: nowrap;
    width: 100%;
    padding-right: 1rem;
    text-align: right;
  }
}
</style>
