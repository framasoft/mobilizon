<template>
  <div class="container section" v-if="group">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.MY_GROUPS }">{{ $t("My groups") }}</router-link>
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ `@${group.preferredUsername}` }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.CONVERSATION_LIST,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Conversations") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <div v-if="group.conversations.elements.length > 0">
        <conversation-list-item
          :conversation="conversation"
          v-for="conversation in group.conversations.elements"
          :key="conversation.id"
        />
      </div>
      <b-button
        tag="router-link"
        :to="{
          name: RouteName.CREATE_CONVERSATION,
          params: { preferredUsername: this.preferredUsername },
        }"
        >{{ $t("New conversation") }}</b-button
      >
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/actor";
import { IGroup, usernameWithDomain } from "@/types/actor";
import ConversationListItem from "@/components/Conversation/ConversationListItem.vue";
import RouteName from "../../router/name";

@Component({
  components: { ConversationListItem },
  apollo: {
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
})
export default class ConversationsList extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  group!: IGroup;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
}
</script>
<style lang="scss">
div.container.section {
  background: white;
}
</style>
