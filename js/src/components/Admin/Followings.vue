<template>
  <div>
    <form @submit="followRelay">
      <b-field
        :label="$t('Add an instance')"
        custom-class="add-relay"
        horizontal
      >
        <b-field grouped expanded size="is-large">
          <p class="control">
            <b-input
              v-model="newRelayAddress"
              :placeholder="$t('Ex: mobilizon.fr')"
            />
          </p>
          <p class="control">
            <b-button type="is-primary" native-type="submit">{{
              $t("Add an instance")
            }}</b-button>
          </p>
        </b-field>
      </b-field>
    </form>
    <b-table
      v-show="relayFollowings.elements.length > 0"
      :data="relayFollowings.elements"
      :loading="$apollo.queries.relayFollowings.loading"
      ref="table"
      :checked-rows.sync="checkedRows"
      :is-row-checkable="(row) => row.id !== 3"
      detailed
      :show-detail-icon="false"
      paginated
      backend-pagination
      :current-page.sync="page"
      :aria-next-label="$t('Next page')"
      :aria-previous-label="$t('Previous page')"
      :aria-page-label="$t('Page')"
      :aria-current-label="$t('Current page')"
      :total="relayFollowings.total"
      :per-page="FOLLOWINGS_PER_PAGE"
      @page-change="onFollowingsPageChange"
      checkable
      checkbox-position="left"
    >
      <b-table-column
        field="targetActor.id"
        label="ID"
        width="40"
        numeric
        v-slot="props"
        >{{ props.row.targetActor.id }}</b-table-column
      >

      <b-table-column
        field="targetActor.type"
        :label="$t('Type')"
        width="80"
        v-slot="props"
      >
        <b-icon
          icon="lan"
          v-if="RelayMixin.isInstance(props.row.targetActor)"
        />
        <b-icon icon="account-circle" v-else />
      </b-table-column>

      <b-table-column
        field="approved"
        :label="$t('Status')"
        width="100"
        sortable
        centered
        v-slot="props"
      >
        <span
          :class="`tag ${props.row.approved ? 'is-success' : 'is-danger'}`"
          >{{ props.row.approved ? $t("Accepted") : $t("Pending") }}</span
        >
      </b-table-column>

      <b-table-column field="targetActor.domain" :label="$t('Domain')" sortable>
        <template v-slot:default="props">
          <a
            @click="toggle(props.row)"
            v-if="RelayMixin.isInstance(props.row.targetActor)"
            >{{ props.row.targetActor.domain }}</a
          >
          <a @click="toggle(props.row)" v-else>{{
            `${props.row.targetActor.preferredUsername}@${props.row.targetActor.domain}`
          }}</a>
        </template>
      </b-table-column>

      <b-table-column
        field="targetActor.updatedAt"
        :label="$t('Date')"
        sortable
        v-slot="props"
      >
        <span
          :title="$options.filters.formatDateTimeString(props.row.updatedAt)"
          >{{
            formatDistanceToNow(new Date(props.row.updatedAt), {
              locale: $dateFnsLocale,
            })
          }}</span
        ></b-table-column
      >

      <template #detail="props">
        <article>
          <div class="content">
            <strong>{{ props.row.targetActor.name }}</strong>
            <small v-if="props.row.actor.preferredUsername !== 'relay'"
              >@{{ props.row.targetActor.preferredUsername }}</small
            >
            <p v-html="props.row.targetActor.summary" />
          </div>
        </article>
      </template>

      <template slot="bottom-left" v-if="checkedRows.length > 0">
        <b-button @click="removeRelays" type="is-danger">
          {{
            $tc(
              "No instance to remove|Remove instance|Remove {number} instances",
              checkedRows.length,
              { number: checkedRows.length }
            )
          }}
        </b-button>
      </template>
    </b-table>
    <b-message type="is-danger" v-if="relayFollowings.total === 0">{{
      $t("You don't follow any instances yet.")
    }}</b-message>
  </div>
</template>
<script lang="ts">
import { Component, Mixins } from "vue-property-decorator";
import { SnackbarProgrammatic as Snackbar } from "buefy";
import { formatDistanceToNow } from "date-fns";
import { ADD_RELAY, REMOVE_RELAY } from "../../graphql/admin";
import { IFollower } from "../../types/actor/follower.model";
import RelayMixin from "../../mixins/relay";
import { RELAY_FOLLOWINGS } from "@/graphql/admin";
import { Paginate } from "@/types/paginate";
import RouteName from "@/router/name";
import { ApolloCache, FetchResult, Reference } from "@apollo/client/core";
import gql from "graphql-tag";

const FOLLOWINGS_PER_PAGE = 10;

@Component({
  apollo: {
    relayFollowings: {
      query: RELAY_FOLLOWINGS,
      variables() {
        return {
          page: this.page,
          limit: FOLLOWINGS_PER_PAGE,
        };
      },
    },
  },
  metaInfo() {
    return {
      title: this.$t("Followings") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Followings extends Mixins(RelayMixin) {
  newRelayAddress = "";

  RelayMixin = RelayMixin;

  formatDistanceToNow = formatDistanceToNow;

  relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };

  FOLLOWINGS_PER_PAGE = FOLLOWINGS_PER_PAGE;

  checkedRows: IFollower[] = [];

  get page(): number {
    return parseInt((this.$route.query.page as string) || "1", 10);
  }

  set page(page: number) {
    this.pushRouter(RouteName.RELAY_FOLLOWINGS, {
      page: page.toString(),
    });
  }

  async onFollowingsPageChange(page: number): Promise<void> {
    this.page = page;
    try {
      await this.$apollo.queries.relayFollowings.fetchMore({
        variables: {
          page: this.page,
          limit: FOLLOWINGS_PER_PAGE,
        },
      });
    } catch (err: any) {
      console.error(err);
    }
  }

  async followRelay(e: Event): Promise<void> {
    e.preventDefault();
    try {
      await this.$apollo.mutate<{ relayFollowings: Paginate<IFollower> }>({
        mutation: ADD_RELAY,
        variables: {
          address: this.newRelayAddress.trim(), // trim to fix copy and paste domain name spaces and tabs
        },
        update(
          cache: ApolloCache<{ relayFollowings: Paginate<IFollower> }>,
          { data }: FetchResult
        ) {
          cache.modify({
            fields: {
              relayFollowings(
                existingFollowings = { elements: [], total: 0 },
                { readField }
              ) {
                const newFollowingRef = cache.writeFragment({
                  id: `${data?.addRelay.__typename}:${data?.addRelay.id}`,
                  data: data?.addRelay,
                  fragment: gql`
                    fragment NewFollowing on Follower {
                      id
                    }
                  `,
                });
                if (
                  existingFollowings.elements.some(
                    (ref: Reference) =>
                      readField("id", ref) === data?.addRelay.id
                  )
                ) {
                  return existingFollowings;
                }
                return {
                  total: existingFollowings.total + 1,
                  elements: [newFollowingRef, ...existingFollowings.elements],
                };
              },
            },
            broadcast: false,
          });
        },
      });
      this.newRelayAddress = "";
    } catch (err: any) {
      if (err.message) {
        Snackbar.open({
          message: err.message,
          type: "is-danger",
          position: "is-bottom",
        });
      }
    }
  }

  removeRelays(): void {
    this.checkedRows.forEach((row: IFollower) => {
      this.removeRelay(row);
    });
  }

  async removeRelay(follower: IFollower): Promise<void> {
    const address = `${follower.targetActor.preferredUsername}@${follower.targetActor.domain}`;
    try {
      await this.$apollo.mutate<{ removeRelay: IFollower }>({
        mutation: REMOVE_RELAY,
        variables: {
          address,
        },
        update(cache: ApolloCache<{ removeRelay: IFollower }>) {
          cache.modify({
            fields: {
              relayFollowings(existingFollowingRefs, { readField }) {
                return {
                  total: existingFollowingRefs.total - 1,
                  elements: existingFollowingRefs.elements.filter(
                    (followingRef: Reference) =>
                      follower.id !== readField("id", followingRef)
                  ),
                };
              },
            },
          });
        },
      });
      await this.$apollo.queries.relayFollowings.refetch();
      this.checkedRows = [];
    } catch (e: any) {
      if (e.message) {
        Snackbar.open({
          message: e.message,
          type: "is-danger",
          position: "is-bottom",
        });
      }
    }
  }
}
</script>
