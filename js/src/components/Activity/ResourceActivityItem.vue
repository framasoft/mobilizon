<template>
  <div class="activity-item">
    <b-icon :icon="'link'" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <router-link v-if="activity.object" slot="resource" :to="path">{{
          subjectParams.resource_title
        }}</router-link>
        <b v-else slot="resource">{{ subjectParams.resource_title }}</b>
        <router-link v-if="activity.object" slot="new_path" :to="path">{{
          parentDirectory
        }}</router-link>
        <b v-else slot="new_path">{{ parentDirectory }}</b>
        <router-link
          v-if="activity.object && subjectParams.old_resource_title"
          slot="old_resource_title"
          :to="path"
          >{{ subjectParams.old_resource_title }}</router-link
        >
        <b
          v-else-if="subjectParams.old_resource_title"
          slot="old_resource_title"
          >{{ subjectParams.old_resource_title }}</b
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
import { ActivityResourceSubject } from "@/types/enums";
import { Component } from "vue-property-decorator";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActivityMixin from "../../mixins/activity";
import { mixins } from "vue-class-component";
import { Location } from "vue-router";

@Component({
  components: {
    PopoverActorCard,
  },
})
export default class ResourceActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;

  get translation(): string | undefined {
    switch (this.activity.subject) {
      case ActivityResourceSubject.RESOURCE_CREATED:
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        if (this.activity?.object?.type === "folder") {
          if (this.isAuthorCurrentActor) {
            return "You created the folder {resource}.";
          }
          return "{profile} created the folder {resource}.";
        }
        if (this.isAuthorCurrentActor) {
          return "You created the resource {resource}.";
        }
        return "{profile} created the resource {resource}.";
      case ActivityResourceSubject.RESOURCE_MOVED:
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        if (this.activity?.object?.type === "folder") {
          if (this.parentDirectory === null) {
            if (this.isAuthorCurrentActor) {
              return "You moved the folder {resource} to the root folder.";
            }
            return "{profile} moved the folder {resource} to the root folder.";
          }
          if (this.isAuthorCurrentActor) {
            return "You moved the folder {resource} into {new_path}.";
          }
          return "{profile} moved the folder {resource} into {new_path}.";
        }
        if (this.parentDirectory === null) {
          if (this.isAuthorCurrentActor) {
            return "You moved the resource {resource} to the root folder.";
          }
          return "{profile} moved the resource {resource} to the root folder.";
        }
        if (this.isAuthorCurrentActor) {
          return "You moved the resource {resource} into {new_path}.";
        }
        return "{profile} moved the resource {resource} into {new_path}.";
      case ActivityResourceSubject.RESOURCE_UPDATED:
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        if (this.activity?.object?.type === "folder") {
          if (this.isAuthorCurrentActor) {
            return "You renamed the folder from {old_resource_title} to {resource}.";
          }
          return "{profile} renamed the folder from {old_resource_title} to {resource}.";
        }
        if (this.isAuthorCurrentActor) {
          return "You renamed the resource from {old_resource_title} to {resource}.";
        }
        return "{profile} renamed the resource from {old_resource_title} to {resource}.";
      case ActivityResourceSubject.RESOURCE_DELETED:
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        if (this.activity?.object?.type === "folder") {
          if (this.isAuthorCurrentActor) {
            return "You deleted the folder {resource}.";
          }
          return "{profile} deleted the folder {resource}.";
        }
        if (this.isAuthorCurrentActor) {
          return "You deleted the resource {resource}.";
        }
        return "{profile} deleted the resource {resource}.";
      default:
        return undefined;
    }
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityResourceSubject.RESOURCE_CREATED:
        return "is-success";
      case ActivityResourceSubject.RESOURCE_MOVED:
      case ActivityResourceSubject.RESOURCE_UPDATED:
        return "is-grey";
      case ActivityResourceSubject.RESOURCE_DELETED:
        return "is-danger";
      default:
        return undefined;
    }
  }

  get path(): Location {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    let path = this.parentPath(this.activity?.object?.path);
    if (path === "") {
      return {
        name: RouteName.RESOURCE_FOLDER_ROOT,
        params: {
          preferredUsername: usernameWithDomain(this.activity.group),
        },
      };
    }
    return {
      name: RouteName.RESOURCE_FOLDER,
      params: {
        path,
        preferredUsername: usernameWithDomain(this.activity.group),
      },
    };
  }

  get parentDirectory(): string | undefined | null {
    if (this.subjectParams.resource_path) {
      const parentPath = this.parentPath(this.subjectParams.resource_path);
      const directory = parentPath.split("/");
      return directory.pop();
    }
    return null;
  }

  parentPath(parent: string): string {
    let path = parent.split("/");
    path.pop();
    return path.join("/").replace(/^\//, "");
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
