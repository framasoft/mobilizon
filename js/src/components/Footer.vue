<template>
  <footer class="footer" ref="footer">
    <img :src="`/img/pics/footer_${random}.jpg`" alt="" />
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

@Component
export default class Footer extends Vue {
  RouteName = RouteName;

  // eslint-disable-next-line class-methods-use-this
  get random(): number {
    return Math.floor(Math.random() * 4) + 1;
  }
}
</script>
<style lang="scss" scoped>
@import "~bulma/sass/utilities/mixins.sass";
footer.footer {
  color: $secondary;
  display: flex;
  flex-direction: column;
  align-items: center;
  font-size: 14px;
  padding: 1rem 1.5rem;

  img {
    flex: 1;
    max-width: 40rem;
    @include mobile {
      max-width: 400px;
    }
  }

  div.content {
    flex: 1;
  }

  ul {
    display: inline-flex;
    flex-wrap: wrap;
    justify-content: space-around;

    li {
      display: inline-flex;
      margin: auto 5px;
      a {
        font-size: 1.1rem;
      }
    }
  }

  a {
    color: $white;
    text-decoration: underline;
    text-decoration-color: $secondary;
  }
}
</style>
