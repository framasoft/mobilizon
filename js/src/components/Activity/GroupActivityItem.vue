<template>
  <div class="activity-item">
    <b-icon :icon="'cog'" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <router-link
          v-if="activity.object"
          slot="group"
          :to="{
            name: RouteName.GROUP,
            params: { preferredUsername: usernameWithDomain(activity.object) },
          }"
          >{{ subjectParams.group_name }}</router-link
        >
        <b v-else slot="post">{{ subjectParams.group_name }}</b>
        <popover-actor-card
          :actor="activity.author"
          :inline="true"
          slot="profile"
        >
          <b>
            {{
              $t("@{username}", {
                username: usernameWithDomain(activity.author),
              })
            }}</b
          ></popover-actor-card
        ></i18n
      >
      <i18n
        :path="detail"
        v-for="detail in details"
        :key="detail"
        tag="p"
        class="has-text-grey"
      >
        <popover-actor-card
          :actor="activity.author"
          :inline="true"
          slot="profile"
        >
          <b>
            {{
              $t("@{username}", {
                username: usernameWithDomain(activity.author),
              })
            }}</b
          ></popover-actor-card
        >
        <router-link
          v-if="activity.object"
          slot="group"
          :to="{
            name: RouteName.GROUP,
            params: { preferredUsername: usernameWithDomain(activity.object) },
          }"
          >{{ subjectParams.group_name }}</router-link
        >
        <b v-else slot="post">{{ subjectParams.group_name }}</b>
        <b v-if="subjectParams.old_group_name" slot="old_group_name">{{
          subjectParams.old_group_name
        }}</b>
      </i18n>
      <small class="has-text-grey activity-date">{{
        activity.insertedAt | formatTimeString
      }}</small>
    </div>
  </div>
</template>
<script lang="ts">
import { usernameWithDomain } from "@/types/actor";
import { ActivityGroupSubject, GroupVisibility, Openness } from "@/types/enums";
import { Component } from "vue-property-decorator";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActivityMixin from "../../mixins/activity";
import { mixins } from "vue-class-component";

@Component({
  components: {
    PopoverActorCard,
  },
})
export default class GroupActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;
  ActivityGroupSubject = ActivityGroupSubject;

  get translation(): string | undefined {
    switch (this.activity.subject) {
      case ActivityGroupSubject.GROUP_CREATED:
        if (this.isAuthorCurrentActor) {
          return "You created the group {group}.";
        }
        return "{profile} created the group {group}.";
      case ActivityGroupSubject.GROUP_UPDATED:
        if (this.isAuthorCurrentActor) {
          return "You updated the group {group}.";
        }
        return "{profile} updated the group {group}.";
      default:
        return undefined;
    }
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityGroupSubject.GROUP_CREATED:
        return "is-success";
      case ActivityGroupSubject.GROUP_UPDATED:
        return "is-grey";
      default:
        return undefined;
    }
  }

  get details(): string[] {
    let details = [];
    const changes = this.subjectParams.group_changes.split(",");
    if (changes.includes("name") && this.subjectParams.old_group_name) {
      details.push("{old_group_name} was renamed to {group}.");
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (changes.includes("visibility") && this.activity.object.visibility) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      switch (this.activity.object.visibility) {
        case GroupVisibility.PRIVATE:
          details.push("Visibility was set to private.");
          break;
        case GroupVisibility.PUBLIC:
          details.push("Visibility was set to public.");
          break;
        default:
          details.push("Visibility was set to an unknown value.");
          break;
      }
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (changes.includes("openness") && this.activity.object.openness) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      switch (this.activity.object.openness) {
        case Openness.INVITE_ONLY:
          details.push("The group can now only be joined with an invite.");
          break;
        case Openness.OPEN:
          details.push("The group can now be joined by anyone.");
          break;
        default:
          details.push("Unknown value for the openness setting.");
          break;
      }
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (changes.includes("address") && this.activity.object.physicalAddress) {
      details.push("The group's physical address was changed.");
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (changes.includes("avatar") && this.activity.object.avatar) {
      details.push("The group's avatar was changed.");
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (changes.includes("banner") && this.activity.object.banner) {
      details.push("The group's banner was changed.");
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    if (changes.includes("summary") && this.activity.object.summary) {
      details.push("The group's short description was changed.");
    }
    return details;
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
