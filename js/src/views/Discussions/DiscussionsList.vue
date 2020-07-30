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
              name: RouteName.DISCUSSION_LIST,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Discussions") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section>
      <div v-if="group.discussions.elements.length > 0">
        <discussion-list-item
          :discussion="discussion"
          v-for="discussion in group.discussions.elements"
          :key="discussion.id"
        />
      </div>
      <b-button
        tag="router-link"
        :to="{
          name: RouteName.CREATE_DISCUSSION,
          params: { preferredUsername: this.preferredUsername },
        }"
        >{{ $t("New discussion") }}</b-button
      >
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { FETCH_GROUP } from "@/graphql/actor";
import { IGroup, usernameWithDomain } from "@/types/actor";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import RouteName from "../../router/name";

@Component({
  components: { DiscussionListItem },
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
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-ignore
      // @ts-ignore
      title: this.$t("Discussions") as string,
      // all titles will be injected into this template
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class DiscussionsList extends Vue {
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
