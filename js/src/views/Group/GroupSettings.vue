<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ group.name }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP_SETTINGS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Settings") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.GROUP_PUBLIC_SETTINGS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("Group settings") }}</router-link
          >
        </li>
      </ul>
    </nav>
    <section class="container section">
      <form @submit.prevent="updateGroup">
        <b-field :label="$t('Group name')">
          <b-input v-model="group.name" />
        </b-field>
        <b-field :label="$t('Group short description')">
          <b-input type="textarea" v-model="group.summary"
        /></b-field>
        <b-button native-type="submit" type="is-primary">{{ $t("Update group") }}</b-button>
      </form>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { FETCH_GROUP, UPDATE_GROUP } from "../../graphql/actor";
import { IGroup, usernameWithDomain } from "../../types/actor";
import { IMember, Group } from "../../types/actor/group.model";
import { Paginate } from "../../types/paginate";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      variables() {
        return {
          name: this.$route.params.preferredUsername,
        };
      },
      skip() {
        return !this.$route.params.preferredUsername;
      },
    },
  },
})
export default class GroupSettings extends Vue {
  group: IGroup = new Group();

  loading = true;

  RouteName = RouteName;

  newMemberUsername = "";

  usernameWithDomain = usernameWithDomain;

  async updateGroup() {
    await this.$apollo.mutate<{ updateGroup: IGroup }>({
      mutation: UPDATE_GROUP,
      variables: {
        ...this.group,
      },
    });
  }
}
</script>
