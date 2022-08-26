<template>
  <div class="activity-item">
    <o-icon :icon="'chat'" :variant="iconColor" custom-size="24" />
    <div class="mt-1 ml-2 prose dark:prose-invert prose-p:m-0">
      <i18n-t :keypath="translation" tag="p">
        <template #discussion>
          <router-link
            v-if="activity.object"
            :to="{
              name: RouteName.DISCUSSION,
              params: { slug: subjectParams.discussion_slug },
            }"
            >{{ subjectParams.discussion_title }}</router-link
          >
          <b v-else>{{ subjectParams.discussion_title }}</b>
        </template>
        <template #old_discussion>
          <router-link
            v-if="activity.object && subjectParams.old_discussion_title"
            :to="{
              name: RouteName.DISCUSSION,
              params: { slug: subjectParams.discussion_slug },
            }"
            >{{ subjectParams.old_discussion_title }}</router-link
          >
          <b v-else-if="subjectParams.old_discussion_title">{{
            subjectParams.old_discussion_title
          }}</b>
        </template>
        <template #profile>
          <popover-actor-card :actor="activity.author" :inline="true">
            <b>
              {{
                $t("{'@'}{username}", {
                  username: usernameWithDomain(activity.author),
                })
              }}</b
            ></popover-actor-card
          ></template
        ></i18n-t
      >
      <small class="has-text-grey-dark activity-date">{{
        formatTimeString(activity.insertedAt)
      }}</small>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { usernameWithDomain } from "@/types/actor";
import { ActivityDiscussionSubject } from "@/types/enums";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import { IActivity } from "@/types/activity.model";
import { computed } from "vue";
import { formatTimeString } from "@/filters/datetime";
import {
  useActivitySubjectParams,
  useIsActivityAuthorCurrentActor,
} from "@/composition/activity";

const props = defineProps<{
  activity: IActivity;
}>();

const isAuthorCurrentActor = useIsActivityAuthorCurrentActor()(props.activity);

const subjectParams = useActivitySubjectParams()(props.activity);

const translation = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityDiscussionSubject.DISCUSSION_CREATED:
      if (isAuthorCurrentActor) {
        return "You created the discussion {discussion}.";
      }
      return "{profile} created the discussion {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_REPLIED:
      if (isAuthorCurrentActor) {
        return "You replied to the discussion {discussion}.";
      }
      return "{profile} replied to the discussion {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_RENAMED:
      if (isAuthorCurrentActor) {
        return "You renamed the discussion from {old_discussion} to {discussion}.";
      }
      return "{profile} renamed the discussion from {old_discussion} to {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_ARCHIVED:
      if (isAuthorCurrentActor) {
        return "You archived the discussion {discussion}.";
      }
      return "{profile} archived the discussion {discussion}.";
    case ActivityDiscussionSubject.DISCUSSION_DELETED:
      if (isAuthorCurrentActor) {
        return "You deleted the discussion {discussion}.";
      }
      return "{profile} deleted the discussion {discussion}.";
    default:
      return undefined;
  }
});

const iconColor = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityDiscussionSubject.DISCUSSION_CREATED:
    case ActivityDiscussionSubject.DISCUSSION_REPLIED:
      return "success";
    case ActivityDiscussionSubject.DISCUSSION_RENAMED:
    case ActivityDiscussionSubject.DISCUSSION_ARCHIVED:
      return "grey";
    case ActivityDiscussionSubject.DISCUSSION_DELETED:
      return "danger";
    default:
      return undefined;
  }
});
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
