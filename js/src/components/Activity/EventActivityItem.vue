<template>
  <div class="activity-item">
    <b-icon :icon="'calendar'" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <router-link
          slot="event"
          v-if="activity.object"
          :to="{
            name: RouteName.EVENT,
            params: { uuid: subjectParams.event_uuid },
          }"
          >{{ subjectParams.event_title }}</router-link
        >
        <b v-else slot="event">{{ subjectParams.event_title }}</b>
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
import { ActivityEventSubject } from "@/types/enums";
import { mixins } from "vue-class-component";
import { Component } from "vue-property-decorator";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActivityMixin from "../../mixins/activity";

@Component({
  components: {
    PopoverActorCard,
  },
})
export default class EventActivityItem extends mixins(ActivityMixin) {
  ActivityEventSubject = ActivityEventSubject;
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;

  get translation(): string | undefined {
    switch (this.activity.subject) {
      case ActivityEventSubject.EVENT_CREATED:
        if (this.isAuthorCurrentActor) {
          return "You created the event {event}.";
        }
        return "The event {event} was created by {profile}.";
      case ActivityEventSubject.EVENT_UPDATED:
        if (this.isAuthorCurrentActor) {
          return "You updated the event {event}.";
        }
        return "The event {event} was updated by {profile}.";
      case ActivityEventSubject.EVENT_DELETED:
        if (this.isAuthorCurrentActor) {
          return "You deleted the event {event}.";
        }
        return "The event {event} was deleted by {profile}.";
      default:
        return undefined;
    }
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityEventSubject.EVENT_CREATED:
        return "is-success";
      case ActivityEventSubject.EVENT_UPDATED:
        return "is-grey";
      case ActivityEventSubject.EVENT_DELETED:
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
