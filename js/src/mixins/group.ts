import {
  CURRENT_ACTOR_CLIENT,
  GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
  PERSON_MEMBERSHIP_GROUP,
} from "@/graphql/actor";
import { FETCH_GROUP } from "@/graphql/group";
import RouteName from "@/router/name";
import {
  Group,
  IActor,
  IGroup,
  IPerson,
  usernameWithDomain,
} from "@/types/actor";
import { MemberRole } from "@/types/enums";
import { Component, Vue } from "vue-property-decorator";

@Component({
  apollo: {
    group: {
      query: FETCH_GROUP,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          name: this.$route.params.preferredUsername,
          beforeDateTime: null,
          afterDateTime: new Date(),
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
      query: PERSON_MEMBERSHIP_GROUP,
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
            group: this.group.preferredUsername,
          };
        },
        skip() {
          return (
            !this.currentActor ||
            !this.currentActor.id ||
            !this.group.preferredUsername
          );
        },
      },
      skip() {
        return (
          !this.currentActor ||
          !this.currentActor.id ||
          !this.group.preferredUsername
        );
      },
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class GroupMixin extends Vue {
  group: IGroup = new Group();

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

  hasCurrentActorThisRole(givenRole: string | string[]): boolean {
    const roles = Array.isArray(givenRole) ? givenRole : [givenRole];
    return (
      this.person?.memberships?.total > 0 &&
      roles.includes(this.person?.memberships?.elements[0].role)
    );
  }

  handleErrors(errors: any[]): void {
    if (
      errors.some((error) => error.status_code === 404) ||
      errors.some(({ message }) => message.includes("has invalid value $uuid"))
    ) {
      this.$router.replace({ name: RouteName.PAGE_NOT_FOUND });
    }
  }
}
