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
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("Nothing to see here") }}</p>
            </div>
          </section>
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
        :loading="$apollo.queries.person.loading"
        paginated
        backend-pagination
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
          <section class="section">
            <div class="content has-text-grey has-text-centered">
              <p>{{ $t("Nothing to see here") }}</p>
            </div>
          </section>
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

const EVENTS_PER_PAGE = 10;

@Component({
  apollo: {
    person: {
      query: GET_PERSON,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          actorId: this.id,
          organizedEventsPage: 1,
          organizedEventsLimit: EVENTS_PER_PAGE,
        };
      },
      skip() {
        return !this.id;
      },
    },
  },
  components: {
    ActorCard,
  },
})
export default class AdminProfile extends Vue {
  @Prop({ required: true }) id!: string;

  person!: IPerson;

  usernameWithDomain = usernameWithDomain;

  RouteName = RouteName;

  EVENTS_PER_PAGE = EVENTS_PER_PAGE;

  organizedEventsPage = 1;

  participationsPage = 1;

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
      update: (store, { data }) => {
        if (data == null) return;
        const profileId = this.id;

        const profileData = store.readQuery<{ person: IPerson }>({
          query: GET_PERSON,
          variables: {
            actorId: profileId,
            organizedEventsPage: 1,
            organizedEventsLimit: EVENTS_PER_PAGE,
          },
        });

        if (!profileData) return;
        const { person } = profileData;
        person.suspended = true;
        person.avatar = null;
        person.name = "";
        person.summary = "";
        store.writeQuery({
          query: GET_PERSON,
          variables: {
            actorId: profileId,
          },
          data: { person },
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

  async onOrganizedEventsPageChange(page: number): Promise<void> {
    this.organizedEventsPage = page;
    await this.$apollo.queries.person.fetchMore({
      variables: {
        actorId: this.id,
        organizedEventsPage: this.organizedEventsPage,
        organizedEventsLimit: EVENTS_PER_PAGE,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newOrganizedEvents =
          fetchMoreResult.person.organizedEvents.elements;
        return {
          person: {
            ...previousResult.person,
            organizedEvents: {
              __typename: previousResult.person.organizedEvents.__typename,
              total: previousResult.person.organizedEvents.total,
              elements: [
                ...previousResult.person.organizedEvents.elements,
                ...newOrganizedEvents,
              ],
            },
          },
        };
      },
    });
  }

  async onParticipationsPageChange(page: number): Promise<void> {
    this.participationsPage = page;
    await this.$apollo.queries.person.fetchMore({
      variables: {
        actorId: this.id,
        participationPage: this.participationsPage,
        participationLimit: EVENTS_PER_PAGE,
      },
      updateQuery: (previousResult, { fetchMoreResult }) => {
        if (!fetchMoreResult) return previousResult;
        const newParticipations =
          fetchMoreResult.person.participations.elements;
        return {
          person: {
            ...previousResult.person,
            participations: {
              __typename: previousResult.person.participations.__typename,
              total: previousResult.person.participations.total,
              elements: [
                ...previousResult.person.participations.elements,
                ...newParticipations,
              ],
            },
          },
        };
      },
    });
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
