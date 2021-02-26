<template>
  <div class="activity-item">
    <b-icon :icon="'chat'" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <router-link
          v-if="activity.object"
          slot="discussion"
          :to="{
            name: RouteName.DISCUSSION,
            params: { slug: subjectParams.discussion_slug },
          }"
          >{{ subjectParams.discussion_title }}</router-link
        >
        <b v-else slot="discussion">{{ subjectParams.discussion_title }}</b>
        <router-link
          v-if="activity.object && subjectParams.old_discussion_title"
          slot="old_discussion"
          :to="{
            name: RouteName.DISCUSSION,
            params: { slug: subjectParams.discussion_slug },
          }"
          >{{ subjectParams.old_discussion_title }}</router-link
        >
        <b
          v-else-if="subjectParams.old_discussion_title"
          slot="old_discussion"
          >{{ subjectParams.old_discussion_title }}</b
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
        ></i18n
      >
      <small class="has-text-grey activity-date">{{
        activity.insertedAt | formatTimeString
      }}</small>
    </div>
  </div>
</template>
<script lang="ts">
import { usernameWithDomain } from "@/types/actor";
import { ActivityDiscussionSubject } from "@/types/enums";
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
export default class DiscussionActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;
  ActivityDiscussionSubject = ActivityDiscussionSubject;

  get translation(): string | undefined {
    switch (this.activity.subject) {
      case ActivityDiscussionSubject.DISCUSSION_CREATED:
        if (this.isAuthorCurrentActor) {
          return "You created the discussion {discussion}.";
        }
        return "{profile} created the discussion {discussion}.";
      case ActivityDiscussionSubject.DISCUSSION_REPLIED:
        if (this.isAuthorCurrentActor) {
          return "You replied to the discussion {discussion}.";
        }
        return "{profile} replied to the discussion {discussion}.";
      case ActivityDiscussionSubject.DISCUSSION_RENAMED:
        if (this.isAuthorCurrentActor) {
          return "You renamed the discussion from {old_discussion} to {discussion}.";
        }
        return "{profile} renamed the discussion from {old_discussion} to {discussion}.";
      case ActivityDiscussionSubject.DISCUSSION_ARCHIVED:
        if (this.isAuthorCurrentActor) {
          return "You archived the discussion {discussion}.";
        }
        return "{profile} archived the discussion {discussion}.";
      case ActivityDiscussionSubject.DISCUSSION_DELETED:
        if (this.isAuthorCurrentActor) {
          return "You deleted the discussion {discussion}.";
        }
        return "{profile} deleted the discussion {discussion}.";
      default:
        return undefined;
    }
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityDiscussionSubject.DISCUSSION_CREATED:
      case ActivityDiscussionSubject.DISCUSSION_REPLIED:
        return "is-success";
      case ActivityDiscussionSubject.DISCUSSION_RENAMED:
      case ActivityDiscussionSubject.DISCUSSION_ARCHIVED:
        return "is-grey";
      case ActivityDiscussionSubject.DISCUSSION_DELETED:
        return "is-danger";
      default:
        return undefined;
    }
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
