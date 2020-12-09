import { PERSON_MEMBERSHIPS, CURRENT_ACTOR_CLIENT } from "@/graphql/actor";
import { GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED } from "@/graphql/event";
import { FETCH_GROUP } from "@/graphql/group";
import RouteName from "@/router/name";
import { Group, IActor, IGroup, IPerson } from "@/types/actor";
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
      query: PERSON_MEMBERSHIPS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          id: this.currentActor.id,
        };
      },
      subscribeToMore: {
        document: GROUP_MEMBERSHIP_SUBSCRIPTION_CHANGED,
        variables() {
          return {
            actorId: this.currentActor.id,
          };
        },
        skip() {
          return !this.currentActor || !this.currentActor.id;
        },
      },
      skip() {
        return !this.currentActor || !this.currentActor.id;
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
      this.person &&
      this.person.memberships.elements.some(
        ({ parent: { id }, role }) =>
          id === this.group.id && roles.includes(role)
      )
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
