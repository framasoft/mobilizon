<template>
  <article class="container" v-if="post">
    <header>
      <div class="banner-container">
        <lazy-image-wrapper :picture="post.picture" />
      </div>
      <div class="heading-section">
        <div class="heading-wrapper">
          <div class="title-metadata">
            <h1 class="title">{{ post.title }}</h1>
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
                v-if="post.visibility === PostVisibility.PRIVATE"
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
        </div>
      </div>
    </header>

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
</template>

<script lang="ts">
import { Component, Prop } from "vue-property-decorator";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";
import { PostVisibility } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import {
  CURRENT_ACTOR_CLIENT,
  PERSON_MEMBERSHIPS,
  PERSON_MEMBERSHIP_GROUP,
} from "../../graphql/actor";
import { FETCH_POST } from "../../graphql/post";
import { IPost } from "../../types/post.model";
import { usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import Tag from "../../components/Tag.vue";
import LazyImageWrapper from "../../components/Image/LazyImageWrapper.vue";
import ActorInline from "../../components/Account/ActorInline.vue";
import { formatDistanceToNowStrict } from "date-fns";

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
    person: {
      query: PERSON_MEMBERSHIP_GROUP,
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

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  formatDistanceToNowStrict = formatDistanceToNowStrict;

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

        .title-metadata {
          min-width: 300px;
          flex: 20;

          p.metadata {
            margin-top: 16px;
            display: flex;
            justify-content: flex-start;
            flex-wrap: wrap;

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
}
</style>
