<template>
  <div>
    <section class="section container">
      <nav class="breadcrumb" aria-label="breadcrumbs" v-if="group">
        <ul>
          <li>
            <router-link :to="{ name: RouteName.MY_GROUPS }">{{ $t("My groups") }}</router-link>
          </li>
          <li>
            <router-link
              v-if="group"
              :to="{
                name: RouteName.GROUP,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ group.name || group.preferredUsername }}</router-link
            >
            <b-skeleton v-else :animated="true"></b-skeleton>
          </li>
          <li class="is-active">
            <router-link
              v-if="group"
              :to="{
                name: RouteName.POSTS,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ $t("Posts") }}</router-link
            >
            <b-skeleton v-else :animated="true"></b-skeleton>
          </li>
        </ul>
      </nav>
      <div v-if="group">
        <router-link
          v-for="post in group.posts.elements"
          :key="post.id"
          :to="{ name: RouteName.POST, params: { slug: post.slug } }"
        >
          {{ post.title }}
        </router-link>
      </div>
      <b-skeleton v-else :animated="true"></b-skeleton>
    </section>
    <pre>{{ group }}</pre>
  </div>
</template>

<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { FETCH_GROUP_POSTS } from "../../graphql/post";
import { Paginate } from "../../types/paginate";
import { IPost } from "../../types/post.model";
import { IGroup, usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP_POSTS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          preferredUsername: this.preferredUsername,
        };
      },
      // update(data) {
      //   console.log(data);
      //   return data.group.posts;
      // },
      skip() {
        return !this.preferredUsername;
      },
    },
  },
})
export default class PostList extends Vue {
  @Prop({ required: true, type: String }) preferredUsername!: string;

  group!: IGroup;

  posts!: Paginate<IPost>;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;
}
</script>
