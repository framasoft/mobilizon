<template>
  <div>
    <div class="hero intro is-small is-primary">
      <div class="hero-body">
        <div class="container">
          <h1 class="title">{{ $t("About Mobilizon") }}</h1>
          <p>
            {{
              $t(
                "A user-friendly, emancipatory and ethical tool for gathering, organising, and mobilising."
              )
            }}
          </p>
          <b-button
            icon-left="open-in-new"
            size="is-large"
            type="is-secondary"
            tag="a"
            href="https://joinmobilizon.org"
            >{{ $t("Learn more") }}</b-button
          >
        </div>
      </div>
    </div>
    <main class="container">
      <div class="columns">
        <div class="column is-one-quarter-desktop">
          <aside class="menu">
            <p class="menu-list">
              <router-link :to="{ name: RouteName.ABOUT_INSTANCE }">{{
                $t("About this instance")
              }}</router-link>
            </p>
            <p class="menu-label">
              {{ $t("Legal") }}
            </p>
            <ul class="menu-list">
              <li>
                <router-link :to="{ name: RouteName.TERMS }">{{
                  $t("Terms of service")
                }}</router-link>
              </li>
              <li>
                <router-link :to="{ name: RouteName.PRIVACY }">{{
                  $t("Privacy policy")
                }}</router-link>
              </li>
              <li>
                <router-link :to="{ name: RouteName.RULES }">{{
                  $t("Instance rules")
                }}</router-link>
              </li>
              <li>
                <router-link :to="{ name: RouteName.GLOSSARY }">{{
                  $t("Glossary")
                }}</router-link>
              </li>
            </ul>
          </aside>
        </div>
        <div class="column router">
          <router-view />
        </div>
      </div>
    </main>

    <!-- We hide the "Find an instance button until https://joinmobilizon.org gets a instance picker -->
    <div class="hero register is-primary is-medium">
      <div class="hero-body">
        <div class="container has-text-centered">
          <div class="columns">
            <div class="column" v-if="config && config.registrationsOpen">
              <h2 class="title">{{ $t("Register on this instance") }}</h2>
              <b-button
                type="is-secondary"
                size="is-large"
                tag="router-link"
                :to="{ name: RouteName.REGISTER }"
                >{{ $t("Create an account") }}</b-button
              >
            </div>
            <div class="column">
              <h2 class="title">{{ $t("Find another instance") }}</h2>
              <b-button
                type="is-secondary"
                size="is-large"
                tag="a"
                href="https://mobilizon.org"
                >{{ $t("Pick an instance") }}</b-button
              >
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import { CONFIG } from "@/graphql/config";
import { IConfig } from "@/types/config.model";
import RouteName from "../router/name";

@Component({
  apollo: {
    config: {
      query: CONFIG,
    },
  },
})
export default class About extends Vue {
  config!: IConfig;

  RouteName = RouteName;
}
</script>

<style lang="scss" scoped>
.hero.is-primary {
  background: $background-color;

  .title {
    margin: 30px auto 1rem auto;
  }

  p {
    margin-bottom: 1rem;
  }
}

.hero.register {
  .title {
    color: $violet-1;
  }
  background: $purple-2;
}

aside.menu {
  position: sticky;
  top: 2rem;
  margin-top: 2rem;
}

.router.column {
  background: $white;
}

ul.menu-list > li > a {
  text-decoration: none;
}
</style>
