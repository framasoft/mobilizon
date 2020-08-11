<template>
  <div class="container is-widescreen">
    <div class="header">
      <nav class="breadcrumb" aria-label="breadcrumbs">
        <ul>
          <li>
            <router-link :to="{ name: RouteName.MY_GROUPS }">{{ $t("My groups") }}</router-link>
          </li>
          <li class="is-active">
            <router-link
              v-if="group.preferredUsername"
              :to="{
                name: RouteName.GROUP,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ group.name }}</router-link
            >
            <b-skeleton v-else :animated="true"></b-skeleton>
          </li>
        </ul>
      </nav>
      <header class="block-container presentation">
        <div class="block-column media">
          <div class="media-left">
            <figure class="image rounded is-128x128" v-if="group.avatar">
              <img :src="group.avatar.url" />
            </figure>
            <b-icon v-else size="is-large" icon="account-group" />
          </div>
          <div class="media-content">
            <h1 v-if="group.name">{{ group.name }}</h1>
            <b-skeleton v-else :animated="true" />
            <small class="has-text-grey" v-if="group.preferredUsername"
              >@{{ usernameWithDomain(group) }}</small
            >
            <b-skeleton v-else :animated="true" />
            <br />
            <router-link
              v-if="isCurrentActorAGroupAdmin"
              :to="{
                name: RouteName.GROUP_PUBLIC_SETTINGS,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-outlined"
              >{{ $t("Group settings") }}</router-link
            >
          </div>
        </div>
        <div class="block-column members" v-if="isCurrentActorAGroupMember">
          <div>
            <figure
              class="image is-48x48"
              :title="
                $t(`@{username} ({role})`, {
                  username: usernameWithDomain(member.actor),
                  role: member.role,
                })
              "
              v-for="member in group.members.elements"
              :key="member.actor.id"
            >
              <img
                class="is-rounded"
                :src="member.actor.avatar.url"
                v-if="member.actor.avatar"
                alt
              />
              <b-icon v-else size="is-large" icon="account-circle" />
            </figure>
          </div>
          <p>
            {{ $t("{count} team members", { count: group.members.total }) }}
            <router-link
              :to="{
                name: RouteName.GROUP_MEMBERS_SETTINGS,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ $t("Add / Remove…") }}</router-link
            >
          </p>
        </div>
        <div class="block-column address" v-else-if="physicalAddress">
          <address>
            <p class="addressDescription" :title="physicalAddress.poiInfos.name">
              {{ physicalAddress.poiInfos.name }}
            </p>
            <p>{{ physicalAddress.poiInfos.alternativeName }}</p>
          </address>
          <span
            class="map-show-button"
            @click="showMap = !showMap"
            v-if="physicalAddress && physicalAddress.geom"
            >{{ $t("Show map") }}</span
          >
        </div>
      </header>
    </div>
    <div v-if="isCurrentActorAGroupMember" class="block-container">
      <div class="block-column">
        <section>
          <subtitle>{{ $t("Upcoming events") }}</subtitle>
          <div class="organized-events-wrapper" v-if="group && group.organizedEvents.total > 0">
            <EventMinimalistCard
              v-for="event in group.organizedEvents.elements"
              :event="event"
              :key="event.uuid"
              class="organized-event"
            />
          </div>
          <div v-else-if="group" class="content has-text-grey has-text-centered">
            <p>{{ $t("No public upcoming events") }}</p>
          </div>
          <b-skeleton animated v-else></b-skeleton>
          <router-link :to="{}">{{ $t("View all events") }}</router-link>
        </section>
        <section>
          <subtitle>{{ $t("Resources") }}</subtitle>
          <div v-if="group.resources.elements.length > 0">
            <div v-for="resource in group.resources.elements" :key="resource.id">
              <resource-item
                :resource="resource"
                v-if="resource.type !== 'folder'"
                :inline="true"
              />
              <folder-item :resource="resource" :group="group" v-else :inline="true" />
            </div>
          </div>
          <div v-else-if="group" class="content has-text-grey has-text-centered">
            <p>{{ $t("No resources yet") }}</p>
          </div>
          <router-link
            :to="{
              name: RouteName.RESOURCE_FOLDER_ROOT,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("View all resources") }}</router-link
          >
        </section>
      </div>
      <div class="block-column">
        <section>
          <subtitle>{{ $t("Public page") }}</subtitle>
          <div v-if="group.posts.total > 0" class="posts-wrapper">
            <post-list-item v-for="post in group.posts.elements" :key="post.id" :post="post" />
          </div>
          <div v-else-if="group" class="content has-text-grey has-text-centered">
            <p>{{ $t("No posts yet") }}</p>
          </div>
          <router-link
            :to="{
              name: RouteName.POST_CREATE,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            class="button is-primary"
            >{{ $t("Post a public message") }}</router-link
          >
        </section>
        <section>
          <subtitle>{{ $t("Ongoing tasks") }}</subtitle>
          <div v-if="group.todoLists.elements.length > 0">
            <div v-for="todoList in group.todoLists.elements" :key="todoList.id">
              <router-link :to="{ name: RouteName.TODO_LIST, params: { id: todoList.id } }">
                <h2 class="is-size-3">
                  {{
                    $tc("{title} ({count} todos)", todoList.todos.total, {
                      count: todoList.todos.total,
                      title: todoList.title,
                    })
                  }}
                </h2>
              </router-link>
              <compact-todo
                :todo="todo"
                v-for="todo in todoList.todos.elements.slice(0, 3)"
                :key="todo.id"
              />
            </div>
          </div>
          <div v-else class="content has-text-grey has-text-centered">
            <p>{{ $t("No ongoing todos") }}</p>
          </div>
          <router-link :to="{ name: RouteName.TODO_LISTS }">{{ $t("View all todos") }}</router-link>
        </section>
        <section>
          <subtitle>{{ $t("Discussions") }}</subtitle>
          <div v-if="group.discussions.total > 0">
            <discussion-list-item
              v-for="discussion in group.discussions.elements"
              :key="discussion.id"
              :discussion="discussion"
            />
          </div>
          <div v-else class="content has-text-grey has-text-centered">
            <p>{{ $t("No discussions yet") }}</p>
          </div>
          <router-link
            :to="{
              name: RouteName.DISCUSSION_LIST,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("View all discussions") }}</router-link
          >
        </section>
      </div>
    </div>
    <b-message v-else-if="!group && $apollo.loading === false" type="is-danger">
      {{ $t("No group found") }}
    </b-message>
    <div v-else class="public-container">
      <section>
        <subtitle>{{ $t("Upcoming events") }}</subtitle>
        <div class="organized-events-wrapper" v-if="group && group.organizedEvents.total > 0">
          <EventMinimalistCard
            v-for="event in group.organizedEvents.elements"
            :event="event"
            :key="event.uuid"
            class="organized-event"
          />
          <router-link :to="{}">{{ $t("View all upcoming events") }}</router-link>
        </div>
        <span v-else-if="group">{{ $t("No public upcoming events") }}</span>
        <b-skeleton animated v-else></b-skeleton>
      </section>
      <!--            {{ group }}-->
      <section>
        <subtitle>{{ $t("Latest posts") }}</subtitle>
        <div v-if="group && group.posts.total > 0">
          <router-link
            v-for="post in group.posts.elements"
            :key="post.id"
            :to="{ name: RouteName.POST, params: { slug: post.slug } }"
          >
            {{ post.title }}
          </router-link>
        </div>
        <span v-else-if="group">{{ $t("No public posts") }}</span>
        <b-skeleton animated v-else></b-skeleton>
      </section>
      <b-modal v-if="physicalAddress && physicalAddress.geom" :active.sync="showMap">
        <div class="map">
          <map-leaflet
            :coords="physicalAddress.geom"
            :marker="{
              text: physicalAddress.fullName,
              icon: physicalAddress.poiInfos.poiIcon.icon,
            }"
          />
        </div>
      </b-modal>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { FETCH_GROUP, CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import {
  IActor,
  IGroup,
  IPerson,
  usernameWithDomain,
  Group as GroupModel,
  MemberRole,
} from "@/types/actor";
import Subtitle from "@/components/Utils/Subtitle.vue";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import EventMinimalistCard from "@/components/Event/EventMinimalistCard.vue";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import PostListItem from "@/components/Post/PostListItem.vue";
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import RouteName from "../../router/name";
import { Address } from "@/types/address.model";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      variables() {
        return {
          name: this.preferredUsername,
        };
      },
    },
    person: {
      query: PERSON_MEMBERSHIPS,
      variables() {
        return {
          id: this.currentActor.id,
        };
      },
      skip() {
        return !this.currentActor || !this.currentActor.id;
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
  components: {
    DiscussionListItem,
    PostListItem,
    EventMinimalistCard,
    CompactTodo,
    Subtitle,
    EventCard,
    FolderItem,
    ResourceItem,
    "map-leaflet": () => import(/* webpackChunkName: "map" */ "../../components/Map.vue"),
  },
  metaInfo() {
    return {
      // if no subcomponents specify a metaInfo.title, this title will be used
      // @ts-ignore
      title: this.groupTitle,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
      meta: [
        // @ts-ignore
        { name: "description", content: this.groupSummary },
      ],
    };
  },
})
export default class Group extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  currentActor!: IActor;

  person!: IPerson;

  group: IGroup = new GroupModel();

  loading = true;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  showMap = false;

  @Watch("currentActor")
  watchCurrentActor(currentActor: IActor, oldActor: IActor) {
    if (currentActor.id && oldActor && currentActor.id !== oldActor.id) {
      this.$apollo.queries.group.refetch();
    }
  }

  get groupTitle() {
    if (!this.group) return undefined;
    return this.group.preferredUsername;
  }

  get groupSummary() {
    if (!this.group) return undefined;
    return this.group.summary;
  }

  get groupMemberships() {
    if (!this.person || !this.person.id) return undefined;
    return this.person.memberships.elements.map(({ parent: { id } }) => id);
  }

  get isCurrentActorAGroupMember(): boolean {
    return this.groupMemberships != undefined && this.groupMemberships.includes(this.group.id);
  }

  get isCurrentActorAGroupAdmin(): boolean {
    return (
      this.person &&
      this.person.memberships.elements.some(
        ({ parent: { id }, role }) => id === this.group.id && role === MemberRole.ADMINISTRATOR
      )
    );
  }

  get physicalAddress(): Address | null {
    if (!this.group.physicalAddress) return null;
    return new Address(this.group.physicalAddress);
  }
}
</script>
<style lang="scss" scoped>
@import "../../variables.scss";

div.container {
  background: white;
  margin-bottom: 3rem;
  padding: 2rem 0;

  .header,
  .public-container {
    margin: auto 2rem;
    display: flex;
    flex-direction: column;
  }

  .block-container {
    display: flex;
    flex-wrap: wrap;

    &.presentation {
      border: 2px solid $purple-2;
      padding: 10px 0;

      h1 {
        color: $purple-1;
        font-size: 2rem;
        font-weight: 500;
      }

      .button.is-outlined {
        border-color: $purple-2;
      }
    }

    .members {
      display: flex;
      flex-direction: column;

      div {
        display: flex;
      }

      figure:not(:first-child) {
        margin-left: -10px;
      }
    }

    div.address {
      flex: 1;
      text-align: right;

      .map-show-button {
        cursor: pointer;
      }

      address {
        font-style: normal;

        span.addressDescription {
          text-overflow: ellipsis;
          white-space: nowrap;
          flex: 1 0 auto;
          min-width: 100%;
          max-width: 4rem;
          overflow: hidden;
        }

        :not(.addressDescription) {
          color: rgba(46, 62, 72, 0.6);
          flex: 1;
          min-width: 100%;
        }
      }
    }

    .block-column {
      flex: 1;
      margin: 0 2rem;

      section {
        /deep/ h2 span {
          display: block;
        }

        .posts-wrapper {
          padding-bottom: 1rem;
        }

        .organized-events-wrapper {
          display: flex;
          flex-wrap: wrap;

          .organized-event {
            margin: 0.25rem 0;
          }
        }

        &.presentation {
          .media-left {
            span.icon.is-large {
              height: 5rem;
              width: 5rem;

              /deep/ i.mdi.mdi-account-group.mdi-48px:before {
                font-size: 100px;
              }
            }
          }

          .media-content {
            h2 {
              color: #3c376e;
              font-family: "Liberation Sans", "Helvetica Neue", Roboto, Helvetica, Arial, serif;
              font-size: 1.5rem;
              font-weight: 700;
            }
          }
        }
      }
    }
  }
}
</style>
