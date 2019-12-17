import { Component, Vue } from 'vue-property-decorator';
import { Refs } from '@/shims-vue';
import { ActorType, IActor } from '@/types/actor';
import { IFollower } from '@/types/actor/follower.model';

@Component
export default class RelayMixin extends Vue {
  $refs!: Refs<{
    table: any,
  }>;

  checkedRows: IFollower[] = [];
  page: number = 1;
  perPage: number = 2;

  toggle(row) {
    this.$refs.table.toggleDetails(row);
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

  isInstance(actor: IActor): boolean {
    return actor.type === ActorType.APPLICATION && (actor.preferredUsername === 'relay' || actor.preferredUsername === actor.domain);
  }
}
