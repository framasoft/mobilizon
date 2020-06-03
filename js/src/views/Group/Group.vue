<template>
  <div class="container is-widescreen">
    <div
      v-if="group && groupMemberships && groupMemberships.includes(group.id)"
      class="block-container"
    >
      <div class="block-column">
        <nav class="breadcrumb" aria-label="breadcrumbs" v-if="group">
          <ul>
            <li>
              <router-link :to="{ name: RouteName.MY_GROUPS }">{{ $t("My groups") }}</router-link>
            </li>
            <li class="is-active">
              <router-link
                :to="{
                  name: RouteName.GROUP,
                  params: { preferredUsername: usernameWithDomain(group.preferredUsername) },
                }"
                >{{ group.name }}</router-link
              >
            </li>
          </ul>
        </nav>
        <section class="presentation">
          <div class="media">
            <div class="media-left">
              <figure class="image is-128x128" v-if="group.avatar">
                <img :src="group.avatar.url" />
              </figure>
              <b-icon v-else size="is-large" icon="account-group" />
            </div>
            <div class="media-content">
              <h1>{{ group.name }}</h1>
              <small class="has-text-grey">@{{ usernameWithDomain(group) }}</small>
            </div>
          </div>
          <div class="members">
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
            </figure>
          </div>
        </section>
        <section>
          <subtitle>{{ $t("Upcoming events") }}</subtitle>
          <div class="organized-events-wrapper" v-if="group.organizedEvents.total > 0">
            <EventMinimalistCard
              v-for="event in group.organizedEvents.elements"
              :event="event"
              :key="event.uuid"
              class="organized-event"
            />
          </div>
          <router-link :to="{}">{{ $t("View all upcoming events") }}</router-link>
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
          <p>{{ $t("Followed by {count} persons", { count: group.members.total }) }}</p>
          <b-button type="is-light">{{ $t("Edit biography") }}</b-button>
          <b-button type="is-primary">{{ $t("Post a public message") }}</b-button>
        </section>
        <section>
          <subtitle>{{ $t("Ongoing tasks") }}</subtitle>
          <div
            v-if="group.todoLists.elements.length > 0"
            v-for="todoList in group.todoLists.elements"
            :key="todoList.id"
          >
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
          <router-link :to="{ name: RouteName.TODO_LISTS }">{{ $t("View all todos") }}</router-link>
        </section>
        <section>
          <subtitle>{{ $t("Discussions") }}</subtitle>
          <conversation-list-item
            v-if="group.conversations.total > 0"
            v-for="conversation in group.conversations.elements"
            :key="conversation.id"
            :conversation="conversation"
          />
          <router-link
            :to="{
              name: RouteName.CONVERSATION_LIST,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("View all conversations") }}</router-link
          >
        </section>
      </div>
    </div>
    <div v-else-if="group">
      <section class="presentation">
        <div class="media">
          <div class="media-left">
            <figure class="image is-128x128" v-if="group.avatar">
              <img :src="group.avatar.url" alt />
            </figure>
            <b-icon v-else size="is-large" icon="account-group" />
          </div>
          <div class="media-content">
            <h2>{{ group.name }}</h2>
            <small class="has-text-grey">@{{ usernameWithDomain(group) }}</small>
          </div>
        </div>
      </section>
      <section>
        <subtitle>{{ $t("Upcoming events") }}</subtitle>
        <div class="organized-events-wrapper" v-if="group.organizedEvents.total > 0">
          <EventMinimalistCard
            v-for="event in group.organizedEvents.elements"
            :event="event"
            :key="event.uuid"
            class="organized-event"
          />
          <router-link :to="{}">{{ $t("View all upcoming events") }}</router-link>
        </div>
        <span v-else>{{ $t("No public upcoming events") }}</span>
      </section>
      <!--            {{ group }}-->
      <section>
        <subtitle>{{ $t("Latest posts") }}</subtitle>
      </section>
    </div>
    <b-message v-else-if="!group && $apollo.loading === false" type="is-danger">
      {{ $t("No group found") }}
    </b-message>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { FETCH_GROUP, CURRENT_ACTOR_CLIENT, PERSON_MEMBERSHIPS } from "@/graphql/actor";
import { IActor, IGroup, IPerson, usernameWithDomain } from "@/types/actor";
import Subtitle from "@/components/Utils/Subtitle.vue";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import EventMinimalistCard from "@/components/Event/EventMinimalistCard.vue";
import ConversationListItem from "@/components/Conversation/ConversationListItem.vue";
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import RouteName from "../../router/name";

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
    ConversationListItem,
    EventMinimalistCard,
    CompactTodo,
    Subtitle,
    EventCard,
    FolderItem,
    ResourceItem,
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

  group!: IGroup;

  loading = true;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

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
}
</script>
<style lang="scss" scoped>
div.container {
  background: white;
  margin-bottom: 3rem;
  padding: 2rem 0;

  .block-container {
    display: flex;
    flex-wrap: wrap;

    .block-column {
      flex: 1;
      margin: 0 2rem;

      section {
        /deep/ h2 span {
          display: block;
        }

        &.presentation {
          .members {
            display: flex;
          }
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
