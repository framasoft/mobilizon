<template>
  <div class="activity-item">
    <b-icon :icon="icon" :type="iconColor" />
    <div class="subject">
      <i18n :path="translation" tag="p">
        <popover-actor-card
          v-if="activity.object"
          :actor="activity.object.actor"
          :inline="true"
          slot="member"
        >
          <b>
            {{
              $t("@{username}", {
                username: usernameWithDomain(activity.object.actor),
              })
            }}</b
          ></popover-actor-card
        >
        <b slot="member" v-else>{{
          subjectParams.member_preferred_username
        }}</b>
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
import { ActivityMemberSubject, MemberRole } from "@/types/enums";
import { Component } from "vue-property-decorator";
import RouteName from "../../router/name";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import ActivityMixin from "../../mixins/activity";
import { mixins } from "vue-class-component";

export const MEMBER_ROLE_VALUE: Record<string, number> = {
  [MemberRole.MEMBER]: 20,
  [MemberRole.MODERATOR]: 50,
  [MemberRole.ADMINISTRATOR]: 90,
  [MemberRole.CREATOR]: 100,
};

@Component({
  components: {
    PopoverActorCard,
  },
})
export default class MemberActivityItem extends mixins(ActivityMixin) {
  usernameWithDomain = usernameWithDomain;
  RouteName = RouteName;
  ActivityMemberSubject = ActivityMemberSubject;

  get translation(): string | undefined {
    switch (this.activity.subject) {
      case ActivityMemberSubject.MEMBER_REQUEST:
        if (this.isAuthorCurrentActor) {
          return "You requested to join the group.";
        }
        return "{member} requested to join the group.";
      case ActivityMemberSubject.MEMBER_INVITED:
        if (this.isAuthorCurrentActor) {
          return "You invited {member}.";
        }
        return "{member} was invited by {profile}.";
      case ActivityMemberSubject.MEMBER_ADDED:
        if (this.isAuthorCurrentActor) {
          return "You added the member {member}.";
        }
        return "{profile} added the member {member}.";
      case ActivityMemberSubject.MEMBER_UPDATED:
        if (this.subjectParams.member_role && this.subjectParams.old_role) {
          return this.roleUpdate;
        }
        if (this.isAuthorCurrentActor) {
          return "You updated the member {member}.";
        }
        return "{profile} updated the member {member}.";
      case ActivityMemberSubject.MEMBER_REMOVED:
        if (this.isAuthorCurrentActor) {
          return "You excluded member {member}.";
        }
        return "{profile} excluded member {member}.";
      case ActivityMemberSubject.MEMBER_QUIT:
        return "{profile} quit the group.";
      case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
        return "{member} rejected the invitation to join the group.";
      case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
        if (this.isAuthorCurrentActor) {
          return "You accepted the invitation to join the group.";
        }
        return "{member} accepted the invitation to join the group.";
      default:
        return undefined;
    }
  }

  get icon(): string {
    switch (this.activity.subject) {
      case ActivityMemberSubject.MEMBER_REQUEST:
      case ActivityMemberSubject.MEMBER_ADDED:
      case ActivityMemberSubject.MEMBER_INVITED:
      case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
        return "account-multiple-plus";
      case ActivityMemberSubject.MEMBER_REMOVED:
      case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
      case ActivityMemberSubject.MEMBER_QUIT:
        return "account-multiple-minus";
      case ActivityMemberSubject.MEMBER_UPDATED:
      default:
        return "account-multiple";
    }
  }

  get iconColor(): string | undefined {
    switch (this.activity.subject) {
      case ActivityMemberSubject.MEMBER_ADDED:
      case ActivityMemberSubject.MEMBER_INVITED:
      case ActivityMemberSubject.MEMBER_JOINED:
      case ActivityMemberSubject.MEMBER_APPROVED:
      case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
        return "is-success";
      case ActivityMemberSubject.MEMBER_REQUEST:
      case ActivityMemberSubject.MEMBER_UPDATED:
        return "is-grey";
      case ActivityMemberSubject.MEMBER_REMOVED:
      case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
      case ActivityMemberSubject.MEMBER_QUIT:
        return "is-danger";
      default:
        return undefined;
    }
  }

  get roleUpdate(): string | undefined {
    if (
      Object.keys(MEMBER_ROLE_VALUE).includes(this.subjectParams.member_role) &&
      Object.keys(MEMBER_ROLE_VALUE).includes(this.subjectParams.old_role)
    ) {
      if (
        MEMBER_ROLE_VALUE[this.subjectParams.member_role] >
        MEMBER_ROLE_VALUE[this.subjectParams.old_role]
      ) {
        switch (this.subjectParams.member_role) {
          case MemberRole.MODERATOR:
            if (this.isAuthorCurrentActor) {
              return "You promoted {member} to moderator.";
            }
            if (this.isObjectMemberCurrentActor) {
              return "You were promoted to moderator by {profile}.";
            }
            return "{profile} promoted {member} to moderator.";
          case MemberRole.ADMINISTRATOR:
            if (this.isAuthorCurrentActor) {
              return "You promoted {member} to administrator.";
            }
            if (this.isObjectMemberCurrentActor) {
              return "You were promoted to administrator by {profile}.";
            }
            return "{profile} promoted {member} to administrator.";
          default:
            if (this.isAuthorCurrentActor) {
              return "You promoted the member {member} to an unknown role.";
            }
            if (this.isObjectMemberCurrentActor) {
              return "You were promoted to an unknown role by {profile}.";
            }
            return "{profile} promoted {member} to an unknown role.";
        }
      } else {
        switch (this.subjectParams.member_role) {
          case MemberRole.MODERATOR:
            if (this.isAuthorCurrentActor) {
              return "You demoted {member} to moderator.";
            }
            if (this.isObjectMemberCurrentActor) {
              return "You were demoted to moderator by {profile}.";
            }
            return "{profile} demoted {member} to moderator.";
          case MemberRole.MEMBER:
            if (this.isAuthorCurrentActor) {
              return "You demoted {member} to simple member.";
            }
            if (this.isObjectMemberCurrentActor) {
              return "You were demoted to simple member by {profile}.";
            }
            return "{profile} demoted {member} to simple member.";
          default:
            if (this.isAuthorCurrentActor) {
              return "You demoted the member {member} to an unknown role.";
            }
            if (this.isObjectMemberCurrentActor) {
              return "You were demoted to an unknown role by {profile}.";
            }
            return "{profile} demoted {member} to an unknown role.";
        }
      }
    } else {
      if (this.isAuthorCurrentActor) {
        return "You updated the member {member}.";
      }
      return "{profile} updated the member {member}";
    }
  }

  get isObjectMemberCurrentActor(): boolean {
    return (
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      this.activity?.object?.actor?.id === this.currentActor?.id &&
      this.currentActor?.id !== undefined
    );
  }
}
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
