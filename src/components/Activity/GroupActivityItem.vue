<template>
  <div class="activity-item">
    <o-icon :icon="'cog'" :variant="iconColor" custom-size="24" />
    <div class="mt-1 ml-2 prose dark:prose-invert prose-p:m-0">
      <i18n-t :keypath="translation" tag="p">
        <template #group>
          <router-link
            v-if="activity.object"
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: subjectParams.group_federated_username,
              },
            }"
            >{{ subjectParams.group_name }}</router-link
          >
          <b v-else>{{ subjectParams.group_name }}</b>
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
      <i18n-t :keypath="detail" v-for="detail in details" :key="detail" tag="p">
        <template #profile>
          <popover-actor-card :actor="activity.author" :inline="true">
            <b>
              {{
                $t("{'@'}{username}", {
                  username: usernameWithDomain(activity.author),
                })
              }}</b
            ></popover-actor-card
          >
        </template>
        <template #group>
          <router-link
            v-if="activity.object"
            :to="{
              name: RouteName.GROUP,
              params: {
                preferredUsername: usernameWithDomain(
                  activity.object as IActor
                ),
              },
            }"
            >{{ subjectParams.group_name }}</router-link
          >
          <b v-else>{{ subjectParams.group_name }}</b>
        </template>
        <template #old_group_name>
          <b v-if="subjectParams.old_group_name">{{
            subjectParams.old_group_name
          }}</b>
        </template>
      </i18n-t>
      <small>{{ formatTimeString(activity.insertedAt) }}</small>
    </div>
  </div>
</template>
<script lang="ts" setup>
import {
  useIsActivityAuthorCurrentActor,
  useActivitySubjectParams,
} from "@/composition/activity";
import { IActivity } from "@/types/activity.model";
import { IActor, IGroup, usernameWithDomain } from "@/types/actor";
import { ActivityGroupSubject, GroupVisibility, Openness } from "@/types/enums";
import { computed } from "vue";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import { formatTimeString } from "@/filters/datetime";

const props = defineProps<{
  activity: IActivity;
}>();

const useIsActivityAuthorCurrentActorFct = useIsActivityAuthorCurrentActor();
const useActivitySubjectParamsFct = useActivitySubjectParams();

const isAuthorCurrentActor = computed(() =>
  useIsActivityAuthorCurrentActorFct(props.activity)
);
const subjectParams = computed(() =>
  useActivitySubjectParamsFct(props.activity)
);

const translation = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityGroupSubject.GROUP_CREATED:
      if (isAuthorCurrentActor.value) {
        return "You created the group {group}.";
      }
      return "{profile} created the group {group}.";
    case ActivityGroupSubject.GROUP_UPDATED:
      if (isAuthorCurrentActor.value) {
        return "You updated the group {group}.";
      }
      return "{profile} updated the group {group}.";
    default:
      return undefined;
  }
});

const iconColor = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityGroupSubject.GROUP_CREATED:
      return "success";
    case ActivityGroupSubject.GROUP_UPDATED:
      return "grey";
    default:
      return undefined;
  }
});

const group = computed(() => props.activity.object as IGroup);

const details = computed((): string[] => {
  const localDetails = [];
  const changes = subjectParams.value.group_changes.split(",");
  if (changes.includes("name") && subjectParams.value.old_group_name) {
    localDetails.push("{old_group_name} was renamed to {group}.");
  }
  if (changes.includes("visibility") && group.value.visibility) {
    switch (group.value.visibility) {
      case GroupVisibility.PRIVATE:
        localDetails.push("Visibility was set to private.");
        break;
      case GroupVisibility.PUBLIC:
        localDetails.push("Visibility was set to public.");
        break;
      default:
        localDetails.push("Visibility was set to an unknown value.");
        break;
    }
  }
  if (changes.includes("openness") && group.value.openness) {
    switch (group.value.openness) {
      case Openness.INVITE_ONLY:
        localDetails.push("The group can now only be joined with an invite.");
        break;
      case Openness.MODERATED:
        localDetails.push(
          "The group can now be joined by anyone, but new members need to be approved by an administrator."
        );
        break;
      case Openness.OPEN:
        localDetails.push("The group can now be joined by anyone.");
        break;
      default:
        localDetails.push("Unknown value for the openness setting.");
        break;
    }
  }
  if (changes.includes("address") && group.value.physicalAddress) {
    localDetails.push("The group's physical address was changed.");
  }
  if (changes.includes("avatar") && group.value.avatar) {
    localDetails.push("The group's avatar was changed.");
  }
  if (changes.includes("banner") && group.value.banner) {
    localDetails.push("The group's banner was changed.");
  }
  if (changes.includes("summary") && group.value.summary) {
    localDetails.push("The group's short description was changed.");
  }
  return localDetails;
});
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
