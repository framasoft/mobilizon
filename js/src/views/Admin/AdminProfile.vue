<template>
  <div v-if="person" class="section">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{
            $t("Admin")
          }}</router-link>
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.PROFILES,
            }"
            >{{ $t("Profiles") }}</router-link
          >
        </li>
        <li class="is-active">
          <router-link
            :to="{
              name: RouteName.PROFILES,
              params: { id: person.id },
            }"
            >{{ person.name || person.preferredUsername }}</router-link
          >
        </li>
      </ul>
    </nav>
    <div class="actor-card">
      <actor-card
        :actor="person"
        :full="true"
        :popover="false"
        :limit="false"
      />
    </div>
    <table v-if="metadata.length > 0" class="table is-fullwidth">
      <tbody>
        <tr v-for="{ key, value, link } in metadata" :key="key">
          <td>{{ key }}</td>
          <td v-if="link">
            <router-link :to="link">
              {{ value }}
            </router-link>
          </td>
          <td v-else>{{ value }}</td>
        </tr>
      </tbody>
    </table>
    <div class="buttons">
      <b-button
        @click="suspendProfile"
        v-if="person.domain && !person.suspended"
        type="is-primary"
        >{{ $t("Suspend") }}</b-button
      >
      <b-button
        @click="unsuspendProfile"
        v-if="person.domain && person.suspended"
        type="is-primary"
        >{{ $t("Unsuspend") }}</b-button
      >
    </div>
    <section>
      <h2 class="subtitle">
        {{
          $tc("{number} organized events", person.organizedEvents.total, {
            number: person.organizedEvents.total,
          })
        }}
      </h2>
      <b-table
        :data="person.organizedEvents.elements"
        :loading="$apollo.queries.person.loading"
        paginated
        backend-pagination
        :current-page.sync="organizedEventsPage"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="person.organizedEvents.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onOrganizedEventsPageChange"
      >
        <b-table-column
          field="beginsOn"
          :label="$t('Begins on')"
          v-slot="props"
        >
          {{ props.row.beginsOn | formatDateTimeString }}
        </b-table-column>
        <b-table-column field="title" :label="$t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
          </router-link>
        </b-table-column>
        <template slot="empty">
          <empty-content icon="account-group" :inline="true">
            {{ $t("No organized events listed") }}
          </empty-content>
        </template>
      </b-table>
    </section>
    <section>
      <h2 class="subtitle">
        {{
          $tc("{number} participations", person.participations.total, {
            number: person.participations.total,
          })
        }}
      </h2>
      <b-table
        :data="
          person.participations.elements.map(
            (participation) => participation.event
          )
        "
        :loading="$apollo.loading"
        paginated
        backend-pagination
        :current-page.sync="participationsPage"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="person.participations.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onParticipationsPageChange"
      >
        <b-table-column
          field="beginsOn"
          :label="$t('Begins on')"
          v-slot="props"
        >
          {{ props.row.beginsOn | formatDateTimeString }}
        </b-table-column>
        <b-table-column field="title" :label="$t('Title')" v-slot="props">
          <router-link
            :to="{ name: RouteName.EVENT, params: { uuid: props.row.uuid } }"
          >
            {{ props.row.title }}
          </router-link>
        </b-table-column>
        <template slot="empty">
          <empty-content icon="account-group" :inline="true">
            {{ $t("No participations listed") }}
          </empty-content>
        </template>
      </b-table>
    </section>
    <section>
      <h2 class="subtitle">
        {{
          $tc("{number} memberships", person.memberships.total, {
            number: person.memberships.total,
          })
        }}
      </h2>
      <b-table
        :data="person.memberships.elements"
        :loading="$apollo.loading"
        paginated
        backend-pagination
        :current-page.sync="membershipsPage"
        :aria-next-label="$t('Next page')"
        :aria-previous-label="$t('Previous page')"
        :aria-page-label="$t('Page')"
        :aria-current-label="$t('Current page')"
        :total="person.memberships.total"
        :per-page="EVENTS_PER_PAGE"
        @page-change="onMembershipsPageChange"
      >
        <b-table-column
          field="parent.preferredUsername"
          :label="$t('Group')"
          v-slot="props"
        >
          <article class="media">
            <figure
              class="media-left image is-48x48"
              v-if="props.row.parent.avatar"
            >
              <img
                class="is-rounded"
                :src="props.row.parent.avatar.url"
                alt=""
              />
            </figure>
            <b-icon
              class="media-left"
              v-else
              size="is-large"
              icon="account-circle"
            />
            <div class="media-content">
              <div class="content">
                <span v-if="props.row.parent.name">{{
                  props.row.parent.name
                }}</span
                ><br />
                <span class="is-size-7 has-text-grey"
                  >@{{ usernameWithDomain(props.row.parent) }}</span
                >
              </div>
            </div>
          </article>
        </b-table-column>
        <b-table-column field="role" :label="$t('Role')" v-slot="props">
          <b-tag
            type="is-primary"
            v-if="props.row.role === MemberRole.ADMINISTRATOR"
          >
            {{ $t("Administrator") }}
          </b-tag>
          <b-tag
            type="is-primary"
            v-else-if="props.row.role === MemberRole.MODERATOR"
          >
            {{ $t("Moderator") }}
          </b-tag>
          <b-tag v-else-if="props.row.role === MemberRole.MEMBER">
            {{ $t("Member") }}
          </b-tag>
          <b-tag
            type="is-warning"
            v-else-if="props.row.role === MemberRole.NOT_APPROVED"
          >
            {{ $t("Not approved") }}
          </b-tag>
          <b-tag
            type="is-danger"
            v-else-if="props.row.role === MemberRole.REJECTED"
          >
            {{ $t("Rejected") }}
          </b-tag>
          <b-tag
            type="is-danger"
            v-else-if="props.row.role === MemberRole.INVITED"
          >
            {{ $t("Invited") }}
          </b-tag>
        </b-table-column>
        <b-table-column field="insertedAt" :label="$t('Date')" v-slot="props">
          <span class="has-text-centered">
            {{ props.row.insertedAt | formatDateString }}<br />{{
              props.row.insertedAt | formatTimeString
            }}
          </span>
        </b-table-column>
        <template slot="empty">
          <empty-content icon="account-group" :inline="true">
            {{ $t("No memberships found") }}
          </empty-content>
        </template>
      </b-table>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { formatBytes } from "@/utils/datetime";
import {
  GET_PERSON,
  SUSPEND_PROFILE,
  UNSUSPEND_PROFILE,
} from "../../graphql/actor";
import { IPerson } from "../../types/actor";
import { usernameWithDomain } from "../../types/actor/actor.model";
import RouteName from "../../router/name";
import ActorCard from "../../components/Account/ActorCard.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { ApolloCache, FetchResult } from "@apollo/client/core";
import VueRouter from "vue-router";
import { MemberRole } from "@/types/enums";
import cloneDeep from "lodash/cloneDeep";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const EVENTS_PER_PAGE = 10;
const PARTICIPATIONS_PER_PAGE = 10;
const MEMBERSHIPS_PER_PAGE = 10;

@Component({
  apollo: {
    person: {
      query: GET_PERSON,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          actorId: this.id,
          organizedEventsPage: this.organizedEventsPage,
          organizedEventsLimit: EVENTS_PER_PAGE,
          participationsPage: this.participationsPage,
          participationLimit: PARTICIPATIONS_PER_PAGE,
          membershipsPage: this.membershipsPage,
          membershipsLimit: MEMBERSHIPS_PER_PAGE,
        };
      },
      skip() {
        return !this.id;
      },
    },
  },
  components: {
    ActorCard,
    EmptyContent,
  },
})
export default class AdminProfile extends Vue {
  @Prop({ required: true }) id!: string;

  person!: IPerson;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  EVENTS_PER_PAGE = EVENTS_PER_PAGE;

  PARTICIPATIONS_PER_PAGE = PARTICIPATIONS_PER_PAGE;

  MEMBERSHIPS_PER_PAGE = MEMBERSHIPS_PER_PAGE;

  MemberRole = MemberRole;

  get organizedEventsPage(): number {
    return parseInt(
      (this.$route.query.organizedEventsPage as string) || "1",
      10
    );
  }

  set organizedEventsPage(page: number) {
    this.pushRouter({ organizedEventsPage: page.toString() });
  }

  get participationsPage(): number {
    return parseInt(
      (this.$route.query.participationsPage as string) || "1",
      10
    );
  }

  set participationsPage(page: number) {
    this.pushRouter({ participationsPage: page.toString() });
  }

  get membershipsPage(): number {
    return parseInt((this.$route.query.membershipsPage as string) || "1", 10);
  }

  set membershipsPage(page: number) {
    this.pushRouter({ membershipsPage: page.toString() });
  }

  get metadata(): Array<Record<string, unknown>> {
    if (!this.person) return [];
    const res: Record<string, unknown>[] = [
      {
        key: this.$t("Status") as string,
        value: this.person.suspended ? this.$t("Suspended") : this.$t("Active"),
      },
      {
        key: this.$t("Domain") as string,
        value: this.person.domain ? this.person.domain : this.$t("Local"),
      },
      {
        key: this.$i18n.t("Uploaded media size"),
        value: formatBytes(this.person.mediaSize),
      },
    ];
    if (!this.person.domain && this.person.user) {
      res.push({
        key: this.$t("User") as string,
        link: {
          name: RouteName.ADMIN_USER_PROFILE,
          params: { id: this.person.user.id },
        },
        value: this.person.user.email,
      });
    }
    return res;
  }

  async suspendProfile(): Promise<void> {
    this.$apollo.mutate<{ suspendProfile: { id: string } }>({
      mutation: SUSPEND_PROFILE,
      variables: {
        id: this.id,
      },
      update: (
        store: ApolloCache<{ suspendProfile: { id: string } }>,
        { data }: FetchResult
      ) => {
        if (data == null) return;
        const profileId = this.id;

        const profileData = store.readQuery<{ person: IPerson }>({
          query: GET_PERSON,
          variables: {
            actorId: profileId,
            organizedEventsPage: 1,
            organizedEventsLimit: EVENTS_PER_PAGE,
            participationsPage: 1,
            participationLimit: PARTICIPATIONS_PER_PAGE,
            membershipsPage: 1,
            membershipsLimit: MEMBERSHIPS_PER_PAGE,
          },
        });

        if (!profileData) return;
        const { person } = profileData;
        store.writeQuery({
          query: GET_PERSON,
          variables: {
            actorId: profileId,
          },
          data: {
            person: {
              ...cloneDeep(person),
              participations: { total: 0, elements: [] },
              suspended: true,
              avatar: null,
              name: "",
              summary: "",
            },
          },
        });
      },
    });
  }

  async unsuspendProfile(): Promise<void> {
    const profileID = this.id;
    this.$apollo.mutate<{ unsuspendProfile: { id: string } }>({
      mutation: UNSUSPEND_PROFILE,
      variables: {
        id: this.id,
      },
      refetchQueries: [
        {
          query: GET_PERSON,
          variables: {
            actorId: profileID,
            organizedEventsPage: 1,
            organizedEventsLimit: EVENTS_PER_PAGE,
          },
        },
      ],
    });
  }

  async onOrganizedEventsPageChange(): Promise<void> {
    await this.$apollo.queries.person.fetchMore({
      variables: {
        actorId: this.id,
        organizedEventsPage: this.organizedEventsPage,
        organizedEventsLimit: EVENTS_PER_PAGE,
      },
    });
  }

  async onParticipationsPageChange(): Promise<void> {
    await this.$apollo.queries.person.fetchMore({
      variables: {
        actorId: this.id,
        participationPage: this.participationsPage,
        participationLimit: PARTICIPATIONS_PER_PAGE,
      },
    });
  }

  async onMembershipsPageChange(): Promise<void> {
    await this.$apollo.queries.person.fetchMore({
      variables: {
        actorId: this.id,
        membershipsPage: this.participationsPage,
        membershipsLimit: MEMBERSHIPS_PER_PAGE,
      },
    });
  }

  private async pushRouter(args: Record<string, string>): Promise<void> {
    try {
      await this.$router.push({
        name: RouteName.ADMIN_PROFILE,
        query: { ...this.$route.query, ...args },
      });
    } catch (e) {
      if (isNavigationFailure(e, NavigationFailureType.redirected)) {
        throw Error(e.toString());
      }
    }
  }
}
</script>

<style lang="scss" scoped>
table,
section {
  margin: 2rem 0;
}

.actor-card {
  background: #fff;
  padding: 1.5rem;
  border-radius: 10px;
}
</style>
