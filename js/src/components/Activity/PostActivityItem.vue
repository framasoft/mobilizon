<template>
  <div class="activity-item">
    <o-icon :icon="'bullhorn'" :variant="iconColor" custom-size="24" />
    <div class="mt-1 ml-2 prose dark:prose-invert prose-p:m-0">
      <i18n-t :keypath="translation" tag="p">
        <template #post>
          <router-link
            v-if="activity.object"
            :to="{
              name: RouteName.POST,
              params: { slug: subjectParams.post_slug },
            }"
            >{{ subjectParams.post_title }}</router-link
          >
          <b v-else>{{ subjectParams.post_title }}</b>
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
import { usernameWithDomain } from "@/types/actor";
import { ActivityPostSubject } from "@/types/enums";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import { formatTimeString } from "@/filters/datetime";
import {
  useIsActivityAuthorCurrentActor,
  useActivitySubjectParams,
} from "@/composition/activity";
import { IActivity } from "@/types/activity.model";
import { computed } from "vue";

const props = defineProps<{
  activity: IActivity;
}>();

const isAuthorCurrentActor = useIsActivityAuthorCurrentActor()(props.activity);

const subjectParams = useActivitySubjectParams()(props.activity);

const translation = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityPostSubject.POST_CREATED:
      if (isAuthorCurrentActor) {
        return "You created the post {post}.";
      }
      return "The post {post} was created by {profile}.";
    case ActivityPostSubject.POST_UPDATED:
      if (isAuthorCurrentActor) {
        return "You updated the post {post}.";
      }
      return "The post {post} was updated by {profile}.";
    case ActivityPostSubject.POST_DELETED:
      if (isAuthorCurrentActor) {
        return "You deleted the post {post}.";
      }
      return "The post {post} was deleted by {profile}.";
    default:
      return undefined;
  }
});

const iconColor = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityPostSubject.POST_CREATED:
      return "success";
    case ActivityPostSubject.POST_UPDATED:
      return "grey";
    case ActivityPostSubject.POST_DELETED:
      return "danger";
    default:
      return undefined;
  }
});
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
