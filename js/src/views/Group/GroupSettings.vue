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
    <section
      class="container section"
      v-if="group && isCurrentActorAGroupAdmin"
    >
      <form @submit.prevent="updateGroup">
        <b-field :label="$t('Group name')">
          <b-input v-model="group.name" />
        </b-field>
        <b-field :label="$t('Group short description')">
          <editor mode="basic" v-model="group.summary" :maxSize="500"
        /></b-field>
        <b-field :label="$t('Avatar')">
          <picture-upload
            :textFallback="$t('Avatar')"
            v-model="avatarFile"
            :defaultImage="group.avatar"
          />
        </b-field>

        <b-field :label="$t('Banner')">
          <picture-upload
            :textFallback="$t('Banner')"
            v-model="bannerFile"
            :defaultImage="group.banner"
          />
        </b-field>
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
            :native-value="GroupVisibility.PRIVATE"
            >{{ $t("Only accessible through link") }}<br />
            <small>{{
              $t(
                "You'll need to transmit the group URL so people may access the group's profile. The group won't be findable in Mobilizon's search or regular search engines."
              )
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

        <p class="label">{{ $t("New members") }}</p>
        <div class="field">
          <b-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.OPEN"
          >
            {{ $t("Anyone can join freely") }}<br />
            <small>{{
              $t(
                "Anyone wanting to be a member from your group will be able to from your group page."
              )
            }}</small>
          </b-radio>
        </div>
        <div class="field">
          <b-radio
            v-model="group.openness"
            name="groupOpenness"
            :native-value="Openness.INVITE_ONLY"
            >{{ $t("Manually invite new members") }}<br />
            <small>{{
              $t(
                "The only way for your group to get new members is if an admininistrator invites them."
              )
            }}</small>
          </b-radio>
        </div>

        <b-field
          :label="$t('Followers')"
          :message="$t('Followers will receive new public events and posts.')"
        >
          <b-checkbox v-model="group.manuallyApprovesFollowers">
            {{ $t("Manually approve new followers") }}
          </b-checkbox>
        </b-field>

        <full-address-auto-complete
          :label="$t('Group address')"
          v-model="group.physicalAddress"
          :value="currentAddress"
        />

        <div class="buttons">
          <b-button native-type="submit" type="is-primary">{{
            $t("Update group")
          }}</b-button>
          <b-button @click="confirmDeleteGroup" type="is-danger">{{
            $t("Delete group")
          }}</b-button>
        </div>
      </form>
    </section>
    <b-message v-else>
      {{ $t("You are not an administrator for this group.") }}
    </b-message>
  </div>
</template>

<script lang="ts">
import { Component } from "vue-property-decorator";
import FullAddressAutoComplete from "@/components/Event/FullAddressAutoComplete.vue";
import { Route } from "vue-router";
import PictureUpload from "@/components/PictureUpload.vue";
import { mixins } from "vue-class-component";
import GroupMixin from "@/mixins/group";
import { GroupVisibility, Openness } from "@/types/enums";
import RouteName from "../../router/name";
import { UPDATE_GROUP, DELETE_GROUP } from "../../graphql/group";
import { IGroup, usernameWithDomain } from "../../types/actor";
import { Address, IAddress } from "../../types/address.model";

@Component({
  components: {
    FullAddressAutoComplete,
    PictureUpload,
    editor: () => import("../../components/Editor.vue"),
  },
})
export default class GroupSettings extends mixins(GroupMixin) {
  loading = true;

  RouteName = RouteName;

  newMemberUsername = "";

  avatarFile: File | null = null;

  bannerFile: File | null = null;

  usernameWithDomain = usernameWithDomain;

  GroupVisibility = GroupVisibility;

  Openness = Openness;

  showCopiedTooltip = false;

  async updateGroup(): Promise<void> {
    const variables = this.buildVariables();
    await this.$apollo.mutate<{ updateGroup: IGroup }>({
      mutation: UPDATE_GROUP,
      variables,
    });
    this.$notifier.success(this.$t("Group settings saved") as string);
  }

  confirmDeleteGroup(): void {
    this.$buefy.dialog.confirm({
      title: this.$t("Delete group") as string,
      message: this.$t(
        "Are you sure you want to <b>completely delete</b> this group? All members - including remote ones - will be notified and removed from the group, and <b>all of the group data (events, posts, discussions, todos…) will be irretrievably destroyed</b>."
      ) as string,
      confirmText: this.$t("Delete group") as string,
      cancelText: this.$t("Cancel") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => this.deleteGroup(),
    });
  }

  async deleteGroup(): Promise<Route> {
    await this.$apollo.mutate<{ deleteGroup: IGroup }>({
      mutation: DELETE_GROUP,
      variables: {
        groupId: this.group.id,
      },
    });
    return this.$router.push({ name: RouteName.MY_GROUPS });
  }

  async copyURL(): Promise<void> {
    await window.navigator.clipboard.writeText(this.group.url);
    this.showCopiedTooltip = true;
    setTimeout(() => {
      this.showCopiedTooltip = false;
    }, 2000);
  }

  private buildVariables() {
    let avatarObj = {};
    let bannerObj = {};
    const variables = { ...this.group };

    // eslint-disable-next-line
    // @ts-ignore
    delete variables.__typename;
    if (variables.physicalAddress) {
      // eslint-disable-next-line
      // @ts-ignore
      delete variables.physicalAddress.__typename;
    }
    delete variables.avatar;
    delete variables.banner;

    if (this.avatarFile) {
      avatarObj = {
        avatar: {
          media: {
            name: this.avatarFile.name,
            alt: `${this.group.preferredUsername}'s avatar`,
            file: this.avatarFile,
          },
        },
      };
    }

    if (this.bannerFile) {
      bannerObj = {
        banner: {
          media: {
            name: this.bannerFile.name,
            alt: `${this.group.preferredUsername}'s banner`,
            file: this.bannerFile,
          },
        },
      };
    }
    return {
      ...variables,
      ...avatarObj,
      ...bannerObj,
    };
  }

  // eslint-disable-next-line class-methods-use-this
  get canShowCopyButton(): boolean {
    return window.isSecureContext;
  }

  get currentAddress(): IAddress {
    return new Address(this.group.physicalAddress);
  }
}
</script>
