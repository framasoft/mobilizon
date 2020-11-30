import { Component, Vue, Ref } from "vue-property-decorator";
import { IActor } from "@/types/actor";
import { IFollower } from "@/types/actor/follower.model";
import { RELAY_FOLLOWERS, RELAY_FOLLOWINGS } from "@/graphql/admin";
import { Paginate } from "@/types/paginate";
import { ActorType } from "@/types/enums";

@Component({
  apollo: {
    relayFollowings: {
      query: RELAY_FOLLOWINGS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          page: this.followingsPage,
          limit: this.perPage,
        };
      },
    },
    relayFollowers: {
      query: RELAY_FOLLOWERS,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          page: this.followersPage,
          limit: this.perPage,
        };
      },
    },
  },
})
export default class RelayMixin extends Vue {
  @Ref("table") readonly table!: any;

  relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };

  relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };

  checkedRows: IFollower[] = [];

  followingsPage = 1;

  followersPage = 1;

  perPage = 10;

  toggle(row: Record<string, unknown>): void {
    this.table.toggleDetails(row);
  }

  async onFollowingsPageChange(page: number): Promise<void> {
    this.followingsPage = page;
    try {
      await this.$apollo.queries.relayFollowings.fetchMore({
        variables: {
          page: this.followingsPage,
          limit: this.perPage,
        },
        updateQuery: (previousResult, { fetchMoreResult }) => {
          if (!fetchMoreResult) return previousResult;
          const newFollowings = fetchMoreResult.relayFollowings.elements;
          return {
            relayFollowings: {
              __typename: previousResult.relayFollowings.__typename,
              total: previousResult.relayFollowings.total,
              elements: [
                ...previousResult.relayFollowings.elements,
                ...newFollowings,
              ],
            },
          };
        },
      });
    } catch (err) {
      console.error(err);
    }
  }

  async onFollowersPageChange(page: number): Promise<void> {
    this.followersPage = page;
    try {
      await this.$apollo.queries.relayFollowers.fetchMore({
        variables: {
          page: this.followersPage,
          limit: this.perPage,
        },
        updateQuery: (previousResult, { fetchMoreResult }) => {
          if (!fetchMoreResult) return previousResult;
          const newFollowers = fetchMoreResult.relayFollowers.elements;
          return {
            relayFollowers: {
              __typename: previousResult.relayFollowers.__typename,
              total: previousResult.relayFollowers.total,
              elements: [
                ...previousResult.relayFollowers.elements,
                ...newFollowers,
              ],
            },
          };
        },
      });
    } catch (err) {
      console.error(err);
    }
  }

  static isInstance(actor: IActor): boolean {
    return (
      actor.type === ActorType.APPLICATION &&
      (actor.preferredUsername === "relay" ||
        actor.preferredUsername === actor.domain)
    );
  }
}
