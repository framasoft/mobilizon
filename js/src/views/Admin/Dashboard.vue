<template>
  <div>
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link :to="{ name: RouteName.ADMIN }">{{ $t("Admin") }}</router-link>
        </li>
        <li class="is-active">
          <router-link :to="{ name: RouteName.ADMIN_DASHBOARD }">{{ $t("Dashboard") }}</router-link>
        </li>
      </ul>
    </nav>
    <section>
      <h1 class="title">{{ $t("Administration") }}</h1>
      <div class="tile is-ancestor" v-if="dashboard">
        <div class="tile is-vertical">
          <div class="tile">
            <div class="tile is-parent is-vertical is-6">
              <article class="tile is-child box">
                <p class="dashboard-number">{{ dashboard.numberOfEvents }}</p>
                <p>{{ $t("Published events") }}</p>
              </article>
              <article class="tile is-child box">
                <p class="dashboard-number">{{ dashboard.numberOfComments }}</p>
                <p>{{ $t("Comments") }}</p>
              </article>
            </div>
            <div class="tile is-parent is-vertical">
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.USERS }">
                  <p class="dashboard-number">{{ dashboard.numberOfUsers }}</p>
                  <p>{{ $t("Users") }}</p>
                </router-link>
              </article>
              <article class="tile is-child box">
                <router-link :to="{ name: RouteName.REPORTS }">
                  <p class="dashboard-number">{{ dashboard.numberOfReports }}</p>
                  <p>{{ $t("Opened reports") }}</p>
                </router-link>
              </article>
            </div>
          </div>
          <div class="tile is-parent" v-if="dashboard.lastPublicEventPublished">
            <router-link
              :to="{
                name: RouteName.EVENT,
                params: { uuid: dashboard.lastPublicEventPublished.uuid },
              }"
            >
              <article class="tile is-child box">
                <p class="dashboard-number">{{ $t("Last published event") }}</p>
                <p class="subtitle">{{ dashboard.lastPublicEventPublished.title }}</p>
                <figure class="image is-4by3" v-if="dashboard.lastPublicEventPublished.picture">
                  <img :src="dashboard.lastPublicEventPublished.picture.url" />
                </figure>
              </article>
            </router-link>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { DASHBOARD } from "@/graphql/admin";
import { IDashboard } from "@/types/admin.model";
import RouteName from "../../router/name";

@Component({
  apollo: {
    dashboard: {
      query: DASHBOARD,
      fetchPolicy: "cache-and-network",
    },
  },
  metaInfo() {
    return {
      title: this.$t("Administration") as string,
      titleTemplate: "%s | Mobilizon",
    };
  },
})
export default class Dashboard extends Vue {
  dashboard!: IDashboard;

  RouteName = RouteName;
}
</script>

<style lang="scss" scoped>
.dashboard-number {
  color: #3c376e;
  font-size: 40px;
  font-weight: 700;
  line-height: 1.125;
}

.tile a,
article.tile a {
  color: #4a4a4a;
  text-decoration: none;
}
</style>
