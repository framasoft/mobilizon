<template>
  <div class="activity-item">
    <o-icon :icon="'calendar'" :type="iconColor" />
    <div class="subject">
      <i18n-t :keypath="translation" tag="p">
        <template #event>
          <router-link
            v-if="activity.object"
            :to="{
              name: RouteName.EVENT,
              params: { uuid: subjectParams.event_uuid },
            }"
            >{{ subjectParams.event_title }}</router-link
          >
          <b v-else>{{ subjectParams.event_title }}</b>
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
      <small class="activity-date">{{
        formatTimeString(activity.insertedAt)
      }}</small>
    </div>
  </div>
</template>
<script lang="ts" setup>
import {
  useActivitySubjectParams,
  useIsActivityAuthorCurrentActor,
} from "@/composition/activity";
import { IActivity } from "@/types/activity.model";
import { usernameWithDomain } from "@/types/actor";
import { formatTimeString } from "@/filters/datetime";
import {
  ActivityEventCommentSubject,
  ActivityEventSubject,
} from "@/types/enums";
import { computed } from "vue";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";

const props = defineProps<{
  activity: IActivity;
}>();

const isAuthorCurrentActor = useIsActivityAuthorCurrentActor()(props.activity);

const subjectParams = useActivitySubjectParams()(props.activity);

const translation = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityEventSubject.EVENT_CREATED:
      if (isAuthorCurrentActor) {
        return "You created the event {event}.";
      }
      return "The event {event} was created by {profile}.";
    case ActivityEventSubject.EVENT_UPDATED:
      if (isAuthorCurrentActor) {
        return "You updated the event {event}.";
      }
      return "The event {event} was updated by {profile}.";
    case ActivityEventSubject.EVENT_DELETED:
      if (isAuthorCurrentActor) {
        return "You deleted the event {event}.";
      }
      return "The event {event} was deleted by {profile}.";
    case ActivityEventCommentSubject.COMMENT_POSTED:
      if (subjectParams.comment_reply_to) {
        if (isAuthorCurrentActor) {
          return "You replied to a comment on the event {event}.";
        }
        return "{profile} replied to a comment on the event {event}.";
      }
      if (isAuthorCurrentActor) {
        return "You posted a comment on the event {event}.";
      }
      return "{profile} posted a comment on the event {event}.";
    default:
      return undefined;
  }
});

const iconColor = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityEventSubject.EVENT_CREATED:
    case ActivityEventCommentSubject.COMMENT_POSTED:
      return "is-success";
    case ActivityEventSubject.EVENT_UPDATED:
      return "is-grey";
    case ActivityEventSubject.EVENT_DELETED:
      return "is-danger";
    default:
      return undefined;
  }
});
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
