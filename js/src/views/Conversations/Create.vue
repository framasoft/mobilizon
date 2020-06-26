<template>
  <section class="section container">
    <h1>{{ $t("Create a discussion") }}</h1>

    <form @submit.prevent="createConversation">
      <b-field :label="$t('Title')">
        <b-input aria-required="true" required v-model="conversation.title" />
      </b-field>

      <b-field :label="$t('Text')">
        <editor v-model="conversation.text" />
      </b-field>

      <button class="button is-primary" type="submit">{{ $t("Create the discussion") }}</button>
    </form>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IGroup, IPerson } from "@/types/actor";
import { CURRENT_ACTOR_CLIENT, FETCH_GROUP } from "@/graphql/actor";
import { CREATE_CONVERSATION } from "@/graphql/conversation";
import RouteName from "../../router/name";

@Component({
  components: {
    editor: () => import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
  },
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
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
export default class CreateConversation extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  group!: IGroup;

  currentActor!: IPerson;

  conversation = { title: "", text: "" };

  async createConversation() {
    try {
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_CONVERSATION,
        variables: {
          title: this.conversation.title,
          text: this.conversation.text,
          actorId: this.group.id,
          creatorId: this.currentActor.id,
        },
        // update: (store, { data: { createConversation } }) => {
        //   // TODO: update group list cache
        // },
      });

      await this.$router.push({
        name: RouteName.CONVERSATION,
        params: {
          id: data.createConversation.id,
          slug: data.createConversation.slug,
        },
      });
    } catch (err) {
      console.error(err);
    }
  }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
