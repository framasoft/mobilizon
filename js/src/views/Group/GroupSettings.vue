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
        <p class="label">{{ $t("Group visibility") }}</p>
        <div class="field">
          <b-radio
            v-model="group.visibility"
            name="groupVisibility"
            :native-value="GroupVisibility.PUBLIC"
          >
            {{ $t("Visible everywhere on the web") }}<br />
            <small>{{
              $t(
                "The group will be publicly listed in search results and may be suggested in the explore section. Only public informations will be shown on it's page."
              )
            }}</small>
          </b-radio>
        </div>
        <div class="field">
          <b-radio
            v-model="group.visibility"
            name="groupVisibility"
            :native-value="GroupVisibility.UNLISTED"
            >{{ $t("Only accessible through link") }}<br />
            <small>{{
              $t("You'll need to transmit the group URL so people may access the group's profile.")
            }}</small>
          </b-radio>
          <p class="control">
            <code>{{ group.url }}</code>
            <b-tooltip
              v-if="canShowCopyButton"
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip"
              always
              type="is-success"
              position="is-left"
            >
              <b-button
                type="is-primary"
                icon-right="content-paste"
                native-type="button"
                @click="copyURL"
                @keyup.enter="copyURL"
              />
            </b-tooltip>
          </p>
        </div>

        <full-address-auto-complete
          :label="$t('Group address')"
          v-model="group.physicalAddress"
          :value="currentAddress"
        />

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
import { Address, IAddress } from "../../types/address.model";
import { IMember, Group } from "../../types/actor/group.model";
import { Paginate } from "../../types/paginate";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";

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
  components: {
    FullAddressAutoComplete,
  },
})
export default class GroupSettings extends Vue {
  group: IGroup = new Group();

  loading = true;

  RouteName = RouteName;

  newMemberUsername = "";

  usernameWithDomain = usernameWithDomain;

  GroupVisibility = {
    PUBLIC: "PUBLIC",
    UNLISTED: "UNLISTED",
  };

  showCopiedTooltip = false;

  async updateGroup() {
    const variables = { ...this.group };
    // eslint-disable-next-line
    // @ts-ignore
    delete variables.__typename;
    // eslint-disable-next-line
    // @ts-ignore
    delete variables.physicalAddress.__typename;
    await this.$apollo.mutate<{ updateGroup: IGroup }>({
      mutation: UPDATE_GROUP,
      variables,
    });
  }

  async copyURL() {
    await window.navigator.clipboard.writeText(this.group.url);
    this.showCopiedTooltip = true;
    setTimeout(() => {
      this.showCopiedTooltip = false;
    }, 2000);
  }

  get canShowCopyButton(): boolean {
    return window.isSecureContext;
  }

  get currentAddress(): IAddress {
    return new Address(this.group.physicalAddress);
  }
}
</script>
