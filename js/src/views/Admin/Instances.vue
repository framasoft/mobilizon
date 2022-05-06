<template>
  <div>
    <breadcrumbs-nav
      :links="[
        { name: RouteName.ADMIN, text: $t('Admin') },
        { text: $t('Instances') },
      ]"
    />
    <section>
      <h1 class="title">{{ $t("Instances") }}</h1>
      <form @submit="followInstance" class="my-4">
        <b-field :label="$t('Follow a new instance')" horizontal>
          <b-field grouped group-multiline expanded size="is-large">
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
              <b-loading
                :is-full-page="true"
                v-model="followInstanceLoading"
                :can-cancel="false"
              />
            </p>
          </b-field>
        </b-field>
      </form>
      <div class="flex flex-wrap gap-2">
        <b-field :label="$t('Follow status')">
          <b-radio-button
            v-model="followStatus"
            :native-value="InstanceFilterFollowStatus.ALL"
            >{{ $t("All") }}</b-radio-button
          >
          <b-radio-button
            v-model="followStatus"
            :native-value="InstanceFilterFollowStatus.FOLLOWING"
            >{{ $t("Following") }}</b-radio-button
          >
          <b-radio-button
            v-model="followStatus"
            :native-value="InstanceFilterFollowStatus.FOLLOWED"
            >{{ $t("Followed") }}</b-radio-button
          >
        </b-field>
        <b-field
          :label="$t('Domain')"
          label-for="domain-filter"
          class="flex-auto"
        >
          <b-input
            id="domain-filter"
            :placeholder="$t('mobilizon-instance.tld')"
            :value="filterDomain"
            @input="debouncedUpdateDomainFilter"
          />
        </b-field>
      </div>
      <div v-if="instances && instances.elements.length > 0" class="mt-3">
        <router-link
          :to="{
            name: RouteName.INSTANCE,
            params: { domain: instance.domain },
          }"
          class="flex items-center mb-2 rounded bg-secondary p-4 flex-wrap justify-center gap-x-2 gap-y-3"
          v-for="instance in instances.elements"
          :key="instance.domain"
        >
          <div class="grow overflow-hidden flex items-center gap-1">
            <img
              class="w-12"
              v-if="instance.hasRelay"
              src="../../assets/logo.svg"
              alt=""
            />
            <b-icon
              class="is-large"
              v-else
              custom-size="mdi-36px"
              icon="cloud-question"
            />
            <div class="">
              <h4 class="text-lg truncate">{{ instance.domain }}</h4>
              <span
                class="text-sm"
                v-if="instance.followedStatus === InstanceFollowStatus.APPROVED"
              >
                <b-icon icon="inbox-arrow-down" />
                {{ $t("Followed") }}</span
              >
              <span
                class="text-sm"
                v-else-if="
                  instance.followedStatus === InstanceFollowStatus.PENDING
                "
              >
                <b-icon icon="inbox-arrow-down" />
                {{ $t("Followed, pending response") }}</span
              >
              <span
                class="text-sm"
                v-if="instance.followerStatus == InstanceFollowStatus.APPROVED"
              >
                <b-icon icon="inbox-arrow-up" />
                {{ $t("Follows us") }}</span
              >
              <span
                class="text-sm"
                v-if="instance.followerStatus == InstanceFollowStatus.PENDING"
              >
                <b-icon icon="inbox-arrow-up" />
                {{ $t("Follows us, pending approval") }}</span
              >
            </div>
          </div>
          <div class="flex-none flex gap-3 ltr:ml-3 rtl:mr-3">
            <p class="flex flex-col text-center">
              <span class="text-xl">{{ instance.eventCount }}</span
              ><span class="text-sm">{{ $t("Events") }}</span>
            </p>
            <p class="flex flex-col text-center">
              <span class="text-xl">{{ instance.personCount }}</span
              ><span class="text-sm">{{ $t("Profiles") }}</span>
            </p>
          </div>
        </router-link>
        <b-pagination
          v-show="instances.total > INSTANCES_PAGE_LIMIT"
          :total="instances.total"
          v-model="instancePage"
          :per-page="INSTANCES_PAGE_LIMIT"
          :aria-next-label="$t('Next page')"
          :aria-previous-label="$t('Previous page')"
          :aria-page-label="$t('Page')"
          :aria-current-label="$t('Current page')"
        >
        </b-pagination>
      </div>
      <div v-else-if="instances && instances.elements.length == 0">
        <empty-content icon="lan-disconnect" :inline="true">
          {{ $t("No instance found.") }}
          <template #desc>
            <span v-if="hasFilter">
              {{
                $t(
                  "No instances match this filter. Try resetting filter fields?"
                )
              }}
            </span>
            <span v-else>
              {{ $t("You haven't interacted with other instances yet.") }}
            </span>
          </template>
        </empty-content>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { ADD_INSTANCE, INSTANCES } from "@/graphql/admin";
import { Paginate } from "@/types/paginate";
import { IFollower } from "@/types/actor/follower.model";
import RouteName from "../../router/name";
import { IInstance } from "@/types/instance.model";
import EmptyContent from "@/components/Utils/EmptyContent.vue";
import VueRouter from "vue-router";
import { debounce } from "lodash";
import {
  InstanceFilterFollowStatus,
  InstanceFollowStatus,
} from "@/types/enums";
const { isNavigationFailure, NavigationFailureType } = VueRouter;

const INSTANCES_PAGE_LIMIT = 10;

@Component({
  apollo: {
    instances: {
      query: INSTANCES,
      fetchPolicy: "cache-and-network",
      variables() {
        return {
          page: this.instancePage,
          limit: INSTANCES_PAGE_LIMIT,
          filterDomain: this.filterDomain,
          filterFollowStatus: this.followStatus,
        };
      },
    },
  },
  metaInfo() {
    return {
      title: this.$t("Federation") as string,
    };
  },
  components: {
    EmptyContent,
  },
})
export default class Follows extends Vue {
  RouteName = RouteName;

  followInstanceLoading = false;

  newRelayAddress = "";

  instances!: Paginate<IInstance>;

  instancePage = 1;

  relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };

  relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };

  InstanceFilterFollowStatus = InstanceFilterFollowStatus;

  InstanceFollowStatus = InstanceFollowStatus;

  INSTANCES_PAGE_LIMIT = INSTANCES_PAGE_LIMIT;

  data(): Record<string, unknown> {
    return {
      debouncedUpdateDomainFilter: debounce(this.updateDomainFilter, 500),
    };
  }

  updateDomainFilter(domain: string) {
    this.filterDomain = domain;
  }

  get filterDomain(): string {
    return (this.$route.query.domain as string) || "";
  }

  set filterDomain(domain: string) {
    this.pushRouter({ domain });
  }

  get followStatus(): InstanceFilterFollowStatus {
    return (
      (this.$route.query.followStatus as InstanceFilterFollowStatus) ||
      InstanceFilterFollowStatus.ALL
    );
  }

  set followStatus(followStatus: InstanceFilterFollowStatus) {
    this.pushRouter({ followStatus });
  }

  get hasFilter(): boolean {
    return (
      this.followStatus !== InstanceFilterFollowStatus.ALL ||
      this.filterDomain !== ""
    );
  }

  async followInstance(e: Event): Promise<void> {
    e.preventDefault();
    this.followInstanceLoading = true;
    const domain = this.newRelayAddress.trim(); // trim to fix copy and paste domain name spaces and tabs
    try {
      await this.$apollo.mutate<{ relayFollowings: Paginate<IFollower> }>({
        mutation: ADD_INSTANCE,
        variables: {
          domain,
        },
      });
      this.newRelayAddress = "";
      this.followInstanceLoading = false;
      this.$router.push({
        name: RouteName.INSTANCE,
        params: { domain },
      });
    } catch (error: any) {
      if (error.message) {
        if (error.graphQLErrors && error.graphQLErrors.length > 0) {
          this.$notifier.error(error.graphQLErrors[0].message);
        }
      }
      this.followInstanceLoading = false;
    }
  }

  private async pushRouter(args: Record<string, string>): Promise<void> {
    try {
      await this.$router.push({
        name: RouteName.INSTANCES,
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
.tab-item {
  form {
    margin-bottom: 1.5rem;
  }
}

a {
  text-decoration: none !important;
}
</style>
