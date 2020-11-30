<template>
  <section class="section container">
    <h1>{{ $t("Create a discussion") }}</h1>

    <form @submit.prevent="createDiscussion">
      <b-field :label="$t('Title')">
        <b-input aria-required="true" required v-model="discussion.title" />
      </b-field>

      <b-field :label="$t('Text')">
        <editor v-model="discussion.text" />
      </b-field>

      <button class="button is-primary" type="submit">
        {{ $t("Create the discussion") }}
      </button>
    </form>
  </section>
</template>

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { IGroup, IPerson } from "@/types/actor";
import { CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { FETCH_GROUP } from "@/graphql/group";
import { CREATE_DISCUSSION } from "@/graphql/discussion";
import RouteName from "../../router/name";

@Component({
  components: {
    editor: () =>
      import(/* webpackChunkName: "editor" */ "@/components/Editor.vue"),
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
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.$t("Create a discussion") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class CreateDiscussion extends Vue {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  group!: IGroup;

  currentActor!: IPerson;

  discussion = { title: "", text: "" };

  async createDiscussion(): Promise<void> {
    try {
      if (!this.group.id || !this.currentActor.id) return;
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_DISCUSSION,
        variables: {
          title: this.discussion.title,
          text: this.discussion.text,
          actorId: parseInt(this.group.id, 10),
        },
      });

      await this.$router.push({
        name: RouteName.DISCUSSION,
        params: {
          id: data.createDiscussion.id,
          slug: data.createDiscussion.slug,
        },
      });
    } catch (error) {
      console.error(error);
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }
}
</script>

<style>
.markdown-render h1 {
  font-size: 2em;
}
</style>
