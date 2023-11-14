<template>
  <div class="activity-item">
    <o-icon :icon="'link'" :variant="iconColor" custom-size="24" />
    <div class="mt-1 ml-2 prose dark:prose-invert prose-p:m-0">
      <i18n-t :keypath="translation" tag="p">
        <template #resource>
          <router-link v-if="activity.object" :to="path">{{
            subjectParams.resource_title
          }}</router-link>
          <b v-else>{{ subjectParams.resource_title }}</b>
        </template>
        <template #new_path>
          <router-link v-if="activity.object" :to="path">{{
            parentDirectory
          }}</router-link>
          <b v-else>{{ parentDirectory }}</b>
        </template>
        <template #old_resource_title>
          <router-link
            v-if="activity.object && subjectParams.old_resource_title"
            :to="path"
            >{{ subjectParams.old_resource_title }}</router-link
          >
          <b v-else-if="subjectParams.old_resource_title">{{
            subjectParams.old_resource_title
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
      <small class="activity-date">{{
        formatTimeString(activity.insertedAt)
      }}</small>
    </div>
  </div>
</template>
<script lang="ts" setup>
import { usernameWithDomain } from "@/types/actor";
import { ActivityResourceSubject } from "@/types/enums";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import { formatTimeString } from "@/filters/datetime";
import {
  useIsActivityAuthorCurrentActor,
  useActivitySubjectParams,
} from "@/composition/activity";
import { IActivity } from "@/types/activity.model";
import { computed } from "vue";
import { IResource } from "@/types/resource";

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

const resource = computed(() => props.activity.object as IResource);

const translation = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityResourceSubject.RESOURCE_CREATED:
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (props.activity?.object?.type === "folder") {
        if (isAuthorCurrentActor.value) {
          return "You created the folder {resource}.";
        }
        return "{profile} created the folder {resource}.";
      }
      if (isAuthorCurrentActor.value) {
        return "You created the resource {resource}.";
      }
      return "{profile} created the resource {resource}.";
    case ActivityResourceSubject.RESOURCE_MOVED:
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (props.activity?.object?.type === "folder") {
        if (parentDirectory.value === null) {
          if (isAuthorCurrentActor.value) {
            return "You moved the folder {resource} to the root folder.";
          }
          return "{profile} moved the folder {resource} to the root folder.";
        }
        if (isAuthorCurrentActor.value) {
          return "You moved the folder {resource} into {new_path}.";
        }
        return "{profile} moved the folder {resource} into {new_path}.";
      }
      if (parentDirectory.value === null) {
        if (isAuthorCurrentActor.value) {
          return "You moved the resource {resource} to the root folder.";
        }
        return "{profile} moved the resource {resource} to the root folder.";
      }
      if (isAuthorCurrentActor.value) {
        return "You moved the resource {resource} into {new_path}.";
      }
      return "{profile} moved the resource {resource} into {new_path}.";
    case ActivityResourceSubject.RESOURCE_UPDATED:
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (props.activity?.object?.type === "folder") {
        if (isAuthorCurrentActor.value) {
          return "You renamed the folder from {old_resource_title} to {resource}.";
        }
        return "{profile} renamed the folder from {old_resource_title} to {resource}.";
      }
      if (isAuthorCurrentActor.value) {
        return "You renamed the resource from {old_resource_title} to {resource}.";
      }
      return "{profile} renamed the resource from {old_resource_title} to {resource}.";
    case ActivityResourceSubject.RESOURCE_DELETED:
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      if (props.activity?.object?.type === "folder") {
        if (isAuthorCurrentActor.value) {
          return "You deleted the folder {resource}.";
        }
        return "{profile} deleted the folder {resource}.";
      }
      if (isAuthorCurrentActor.value) {
        return "You deleted the resource {resource}.";
      }
      return "{profile} deleted the resource {resource}.";
    default:
      return undefined;
  }
});

const iconColor = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityResourceSubject.RESOURCE_CREATED:
      return "success";
    case ActivityResourceSubject.RESOURCE_MOVED:
    case ActivityResourceSubject.RESOURCE_UPDATED:
      return "grey";
    case ActivityResourceSubject.RESOURCE_DELETED:
      return "danger";
    default:
      return undefined;
  }
});

const path = computed(() => {
  const localPath = parentPath(resource.value?.path);
  if (localPath === "") {
    return {
      name: RouteName.RESOURCE_FOLDER_ROOT,
      params: {
        preferredUsername: usernameWithDomain(props.activity.group),
      },
    };
  }
  return {
    name: RouteName.RESOURCE_FOLDER,
    params: {
      path: localPath,
      preferredUsername: usernameWithDomain(props.activity.group),
    },
  };
});

const parentPath = (parent: string | undefined): string | undefined => {
  if (!parent) return undefined;
  const localPath = parent.split("/");
  localPath.pop();
  return localPath.join("/").replace(/^\//, "");
};

const parentDirectory = computed((): string | undefined | null => {
  if (subjectParams.value.resource_path) {
    const parentPathResult = parentPath(subjectParams.value.resource_path);
    const directory = parentPathResult?.split("/");
    const res = directory?.pop();
    res === "" ? null : res;
  }
  return null;
});
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
