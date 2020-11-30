<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{
            $t("Admin")
          }}</router-link>
        </li>
        <li>
          <router-link :to="{ name: RouteName.RELAYS }">{{
            $t("Federation")
          }}</router-link>
        </li>
        <li class="is-active" v-if="$route.name == RouteName.RELAY_FOLLOWINGS">
          <router-link :to="{ name: RouteName.RELAY_FOLLOWINGS }">{{
            $t("Followings")
          }}</router-link>
        </li>
        <li class="is-active" v-if="$route.name == RouteName.RELAY_FOLLOWERS">
          <router-link :to="{ name: RouteName.RELAY_FOLLOWERS }">{{
            $t("Followers")
          }}</router-link>
        </li>
      </ul>
    </nav>
    <section>
      <h1 class="title">{{ $t("Instances") }}</h1>
      <div class="tabs is-boxed">
        <ul>
          <router-link
            tag="li"
            active-class="is-active"
            :to="{ name: RouteName.RELAY_FOLLOWINGS }"
            exact
          >
            <a>
              <b-icon icon="inbox-arrow-down"></b-icon>
              <span>
                {{ $t("Followings") }}
                <b-tag rounded>{{ relayFollowings.total }}</b-tag>
              </span>
            </a>
          </router-link>
          <router-link
            tag="li"
            active-class="is-active"
            :to="{ name: RouteName.RELAY_FOLLOWERS }"
            exact
          >
            <a>
              <b-icon icon="inbox-arrow-up"></b-icon>
              <span>
                {{ $t("Followers") }}
                <b-tag rounded>{{ relayFollowers.total }}</b-tag>
              </span>
            </a>
          </router-link>
        </ul>
      </div>
      <router-view></router-view>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { RELAY_FOLLOWERS, RELAY_FOLLOWINGS } from "@/graphql/admin";
import { Paginate } from "@/types/paginate";
import { IFollower } from "@/types/actor/follower.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    relayFollowings: {
      query: RELAY_FOLLOWINGS,
      fetchPolicy: "cache-and-network",
      variables: {
        page: 1,
        limit: 10,
      },
    },
    relayFollowers: {
      query: RELAY_FOLLOWERS,
      fetchPolicy: "cache-and-network",
      variables: {
        page: 1,
        limit: 10,
      },
    },
  },
})
export default class Follows extends Vue {
  RouteName = RouteName;

  activeTab = 0;

  relayFollowings: Paginate<IFollower> = { elements: [], total: 0 };

  relayFollowers: Paginate<IFollower> = { elements: [], total: 0 };
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
