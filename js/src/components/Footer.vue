<template>
  <footer class="footer" ref="footer">
    <mobilizon-logo :invert="true" class="logo" />
    <!-- <img src="../assets/footer.png" :alt="$t('World map')" /> -->
    <ul>
      <li>
        <router-link :to="{ name: RouteName.ABOUT }">{{ $t("About") }}</router-link>
      </li>
      <li>
        <router-link :to="{ name: RouteName.TERMS }">{{ $t("Terms") }}</router-link>
      </li>
      <li>
        <a hreflang="en" href="https://framagit.org/framasoft/mobilizon/blob/master/LICENSE">
          {{ $t("License") }}
        </a>
      </li>
    </ul>
    <div class="content has-text-centered">
      <i18n
        tag="span"
        path="Powered by {mobilizon}. © 2018 - {date} The Mobilizon Contributors - Made with the financial support of {contributors}."
      >
        <a slot="mobilizon" href="https://joinmobilizon.org">{{ $t("Mobilizon") }}</a>
        <span slot="date">{{ new Date().getFullYear() }}</span>
        <a href="https://joinmobilizon.org/hall-of-fame" slot="contributors">{{
          $t("more than 1360 contributors")
        }}</a>
      </i18n>
    </div>
  </footer>
</template>
<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import RouteName from "../router/name";
import Logo from "./Logo.vue";

@Component({
  components: {
    "mobilizon-logo": Logo,
  },
})
export default class Footer extends Vue {
  RouteName = RouteName;
}
</script>
<style lang="scss" scoped>
@import "../variables.scss";

footer.footer {
  color: $secondary;
  display: flex;
  flex-direction: column;
  align-items: center;
  font-size: 14px;

  .logo {
    fill: $secondary;
    flex: 1;
    max-width: 300px;
    margin-bottom: 2rem;
  }

  div.content {
    flex: 1;
  }

  ul li {
    display: inline-flex;
    margin: auto 5px;
    a {
      font-size: 1.1rem;
    }
  }

  a {
    color: $white;
    text-decoration: underline;
    text-decoration-color: $secondary;
  }
}
</style>
