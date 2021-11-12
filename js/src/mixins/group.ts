import {
  CURRENT_ACTOR_CLIENT,
  GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
  PERSON_STATUS_GROUP,
} from "@/graphql/actor";
import { DELETE_GROUP, FETCH_GROUP } from "@/graphql/group";
import RouteName from "@/router/name";
import {
  IActor,
  IFollower,
  IGroup,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
import { MemberRole } from "@/types/enums";
import { Component, Vue } from "vue-property-decorator";
import { Route } from "vue-router";

const now = new Date();

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          beforeDateTime: null,
          afterDateTime: now,
        };
      },
      skip() {
        return !this.$route.params.preferredUsername;
      },
      error({ graphQLErrors }) {
        this.handleErrors(graphQLErrors);
      },
    },
    person: {
      query: PERSON_STATUS_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
          group: usernameWithDomain(this.group),
        };
      },
      subscribeToMore: {
        document: GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
        variables() {
          return {
            actorId: this.currentActor.id,
            group: this.group?.preferredUsername,
          };
        },
        skip() {
          return (
            !this.currentActor ||
            !this.currentActor.id ||
            !this.group?.preferredUsername
          );
        },
      },
      skip() {
        return (
          !this.currentActor ||
          !this.currentActor.id ||
          !this.group?.preferredUsername
        );
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class GroupMixin extends Vue {
  group!: IGroup;

  currentActor!: IActor;

  person!: IPerson;

  get isCurrentActorAGroupAdmin(): boolean {
    return this.hasCurrentActorThisRole(MemberRole.ADMINISTRATOR);
  }

  get isCurrentActorAGroupModerator(): boolean {
    return this.hasCurrentActorThisRole([
      MemberRole.MODERATOR,
      MemberRole.ADMINISTRATOR,
    ]);
  }

  get isCurrentActorAGroupMember(): boolean {
    return this.hasCurrentActorThisRole([
      MemberRole.MODERATOR,
      MemberRole.ADMINISTRATOR,
      MemberRole.MEMBER,
    ]);
  }

  get isCurrentActorAPendingGroupMember(): boolean {
    return this.hasCurrentActorThisRole([MemberRole.NOT_APPROVED]);
  }

  hasCurrentActorThisRole(givenRole: string | string[]): boolean {
    const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
    return (
      this.person?.memberships?.total > 0 &&
      roles.includes(this.person?.memberships?.elements[0].role)
    );
  }

  get isCurrentActorFollowing(): boolean {
    return this.currentActorFollow?.approved === true;
  }

  get isCurrentActorPendingFollow(): boolean {
    return this.currentActorFollow?.approved === false;
  }

  get isCurrentActorFollowingNotify(): boolean {
    return (
      this.isCurrentActorFollowing && this.currentActorFollow?.notify === true
    );
  }

  get currentActorFollow(): IFollower | null {
    if (this.person?.follows?.total > 0) {
      return this.person?.follows?.elements[0];
    }
    return null;
  }

  handleErrors(errors: any[]): void {
    if (
      errors.some((error) => error.status_code === 404) ||
      errors.some(({ message }) => message.includes("has invalid value $uuid"))
    ) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }

  confirmDeleteGroup(): void {
    this.$buefy.dialog.confirm({
      title: this.$t("Delete group") as string,
      message: this.$t(
        "Are you sure you want to <b>completely delete</b> this group? All members - including remote ones - will be notified and removed from the group, and <b>all of the group data (events, posts, discussions, todos…) will be irretrievably destroyed</b>."
      ) as string,
      confirmText: this.$t("Delete group") as string,
      cancelText: this.$t("Cancel") as string,
      type: "is-danger",
      hasIcon: true,
      onConfirm: () => this.deleteGroup(),
    });
  }

  async deleteGroup(): Promise<Route> {
    await this.$apollo.mutate<{ deleteGroup: IGroup }>({
      mutation: DELETE_GROUP,
      variables: {
        groupId: this.group.id,
      },
    });
    return this.$router.push({ name: RouteName.MY_GROUPS });
  }
}
