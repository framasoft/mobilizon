<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.GROUP }">{{ group.name }}</router-link>
        </li>
        <li>
          <router-link :to="{ name: RouteName.GROUP_SETTINGS }">{{ $t("Settings") }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.GROUP_MEMBERS_SETTINGS }">{{
            $t("Members")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section class="container section" v-if="group">
      <form @submit.prevent="inviteMember">
        <b-field :label="$t('Invite a new member')" custom-class="add-relay" horizontal>
          <b-field grouped expanded size="is-large">
            <p class="control">
              <b-input v-model="newMemberUsername" :placeholder="$t('Ex: someone@mobilizon.org')" />
            </p>
            <p class="control">
              <b-button type="is-primary" native-type="submit">{{ $t("Invite member") }}</b-button>
            </p>
          </b-field>
        </b-field>
      </form>
      <h1>{{ $t("Group Members") }} ({{ group.members.total }})</h1>
      <pre>{{ group.members }}</pre>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import RouteName from "../../router/name";
import { FETCH_GROUP } from "../../graphql/actor";
import { INVITE_MEMBER } from "../../graphql/member";
import { IGroup } from "../../types/actor";
import { IMember } from "../../types/actor/group.model";

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
export default class GroupMembers extends Vue {
  group!: IGroup;

  loading = true;

  RouteName = RouteName;

  newMemberUsername = "";

  async inviteMember() {
    await this.$apollo.mutate<{ inviteMember: IMember }>({
      mutation: INVITE_MEMBER,
      variables: {
        groupId: this.group.id,
        targetActorUsername: this.newMemberUsername,
      },
    });
  }
}
</script>
