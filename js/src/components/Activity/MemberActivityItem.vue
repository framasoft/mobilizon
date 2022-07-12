<template>
  <div class="activity-item">
    <o-icon :icon="icon" :type="iconColor" />
    <div class="subject">
      <i18n-t :keypath="translation" tag="p">
        <template #member>
          <popover-actor-card
            v-if="member"
            :actor="member.actor"
            :inline="true"
          >
            <b> {{ displayName(member.actor) }}</b></popover-actor-card
          >
          <b v-else>{{ subjectParams.member_actor_federated_username }}</b>
        </template>
        <template #profile>
          <popover-actor-card :actor="activity.author" :inline="true">
            <b> {{ displayName(activity.author) }}</b></popover-actor-card
          ></template
        ></i18n-t
      >
      <small class="activity-date">{{
        formatTimeString(activity.insertedAt)
      }}</small>
    </div>
  </div>
</template>
<script lang="ts">
export const MEMBER_ROLE_VALUE: Record<string, number> = {
  [MemberRole.MEMBER]: 20,
  [MemberRole.MODERATOR]: 50,
  [MemberRole.ADMINISTRATOR]: 90,
  [MemberRole.CREATOR]: 100,
};
</script>
<script lang="ts" setup>
import { displayName } from "@/types/actor";
import { ActivityMemberSubject, MemberRole } from "@/types/enums";
import PopoverActorCard from "../Account/PopoverActorCard.vue";
import { formatTimeString } from "@/filters/datetime";
import {
  useIsActivityAuthorCurrentActor,
  useActivitySubjectParams,
  useIsActivityObjectCurrentActor,
} from "@/composition/activity";
import { IActivity } from "@/types/activity.model";
import { computed } from "vue";
import { IMember } from "@/types/actor/member.model";

const props = defineProps<{
  activity: IActivity;
}>();

const isAuthorCurrentActor = useIsActivityAuthorCurrentActor()(props.activity);

const subjectParams = useActivitySubjectParams()(props.activity);
const member = computed(() => props.activity.object as IMember);

const isObjectMemberCurrentActor = useIsActivityObjectCurrentActor()(
  props.activity
);

const translation = computed((): string | undefined => {
  switch (props.activity.subject) {
    case ActivityMemberSubject.MEMBER_REQUEST:
      if (isAuthorCurrentActor) {
        return "You requested to join the group.";
      }
      return "{member} requested to join the group.";
    case ActivityMemberSubject.MEMBER_INVITED:
      if (isAuthorCurrentActor) {
        return "You invited {member}.";
      }
      return "{member} was invited by {profile}.";
    case ActivityMemberSubject.MEMBER_ADDED:
      if (isAuthorCurrentActor) {
        return "You added the member {member}.";
      }
      return "{profile} added the member {member}.";
    case ActivityMemberSubject.MEMBER_APPROVED:
      if (isAuthorCurrentActor) {
        return "You approved {member}'s membership.";
      }
      if (isObjectMemberCurrentActor) {
        return "Your membership was approved by {profile}.";
      }
      return "{profile} approved {member}'s membership.";
    case ActivityMemberSubject.MEMBER_JOINED:
      return "{member} joined the group.";
    case ActivityMemberSubject.MEMBER_UPDATED:
      if (subjectParams.member_role && subjectParams.old_role) {
        return roleUpdate.value;
      }
      if (isAuthorCurrentActor) {
        return "You updated the member {member}.";
      }
      return "{profile} updated the member {member}.";
    case ActivityMemberSubject.MEMBER_REMOVED:
      if (subjectParams.member_role === MemberRole.NOT_APPROVED) {
        if (isAuthorCurrentActor) {
          return "You rejected {member}'s membership request.";
        }
        return "{profile} rejected {member}'s membership request.";
      }
      if (isAuthorCurrentActor) {
        return "You excluded member {member}.";
      }
      return "{profile} excluded member {member}.";
    case ActivityMemberSubject.MEMBER_QUIT:
      return "{profile} quit the group.";
    case ActivityMemberSubject.MEMBER_REJECTED_INVITATION:
      return "{member} rejected the invitation to join the group.";
    case ActivityMemberSubject.MEMBER_ACCEPTED_INVITATION:
      if (isAuthorCurrentActor) {
        return "You accepted the invitation to join the group.";
      }
      return "{member} accepted the invitation to join the group.";
    default:
      return undefined;
  }
});

const icon = computed((): string => {
  switch (props.activity.subject) {
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
});

const iconColor = computed((): string | undefined => {
  switch (props.activity.subject) {
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
});

const roleUpdate = computed((): string | undefined => {
  if (
    Object.keys(MEMBER_ROLE_VALUE).includes(subjectParams.member_role) &&
    Object.keys(MEMBER_ROLE_VALUE).includes(subjectParams.old_role)
  ) {
    if (
      MEMBER_ROLE_VALUE[subjectParams.member_role] >
      MEMBER_ROLE_VALUE[subjectParams.old_role]
    ) {
      switch (subjectParams.member_role) {
        case MemberRole.MODERATOR:
          if (isAuthorCurrentActor) {
            return "You promoted {member} to moderator.";
          }
          if (isObjectMemberCurrentActor) {
            return "You were promoted to moderator by {profile}.";
          }
          return "{profile} promoted {member} to moderator.";
        case MemberRole.ADMINISTRATOR:
          if (isAuthorCurrentActor) {
            return "You promoted {member} to administrator.";
          }
          if (isObjectMemberCurrentActor) {
            return "You were promoted to administrator by {profile}.";
          }
          return "{profile} promoted {member} to administrator.";
        default:
          if (isAuthorCurrentActor) {
            return "You promoted the member {member} to an unknown role.";
          }
          if (isObjectMemberCurrentActor) {
            return "You were promoted to an unknown role by {profile}.";
          }
          return "{profile} promoted {member} to an unknown role.";
      }
    } else {
      switch (subjectParams.member_role) {
        case MemberRole.MODERATOR:
          if (isAuthorCurrentActor) {
            return "You demoted {member} to moderator.";
          }
          if (isObjectMemberCurrentActor) {
            return "You were demoted to moderator by {profile}.";
          }
          return "{profile} demoted {member} to moderator.";
        case MemberRole.MEMBER:
          if (isAuthorCurrentActor) {
            return "You demoted {member} to simple member.";
          }
          if (isObjectMemberCurrentActor) {
            return "You were demoted to simple member by {profile}.";
          }
          return "{profile} demoted {member} to simple member.";
        default:
          if (isAuthorCurrentActor) {
            return "You demoted the member {member} to an unknown role.";
          }
          if (isObjectMemberCurrentActor) {
            return "You were demoted to an unknown role by {profile}.";
          }
          return "{profile} demoted {member} to an unknown role.";
      }
    }
  } else {
    if (isAuthorCurrentActor) {
      return "You updated the member {member}.";
    }
    return "{profile} updated the member {member}";
  }
});
</script>
<style lang="scss" scoped>
@import "./activity.scss";
</style>
