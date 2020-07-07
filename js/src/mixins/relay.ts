import { Component, Vue, Ref } from "vue-property-decorator";
import { ActorType, IActor } from "@/types/actor";
import { IFollower } from "@/types/actor/follower.model";
import TimeAgo from "javascript-time-ago";

@Component
export default class RelayMixin extends Vue {
  @Ref("table") readonly table!: any;

  checkedRows: IFollower[] = [];

  page = 1;

  perPage = 10;

  timeAgoInstance: TimeAgo | null = null;

  async mounted() {
    const localeName = this.$i18n.locale;
    const locale = await import(`javascript-time-ago/locale/${localeName}`);
    TimeAgo.addLocale(locale);
    this.timeAgoInstance = new TimeAgo(localeName);
  }

  toggle(row: object) {
    this.table.toggleDetails(row);
  }

  async onPageChange(page: number) {
    this.page = page;
    await this.$apollo.queries.relayFollowings.fetchMore({
      variables: {
        page: this.page,
        limit: this.perPage,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newFollowings = fetchMoreResult.relayFollowings.elements;
        return {
          relayFollowings: {
            __typename: previousResult.relayFollowings.__typename,
            total: previousResult.relayFollowings.total,
            elements: [...previousResult.relayFollowings.elements, ...newFollowings],
          },
        };
      },
    });
  }

  static isInstance(actor: IActor): boolean {
    return (
      actor.type === ActorType.APPLICATION &&
      (actor.preferredUsername === "relay" || actor.preferredUsername === actor.domain)
    );
  }

  timeago(dateTime: string): string {
    if (this.timeAgoInstance != null) {
      return this.timeAgoInstance.format(new Date(dateTime));
    }
    return "";
  }
}
