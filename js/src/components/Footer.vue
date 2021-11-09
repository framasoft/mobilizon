<template>
  <footer class="footer" ref="footer">
    <picture>
      <source
        :srcset="`/img/pics/footer_${random}-1024w.webp 1x, /img/pics/footer_${random}-1920w.webp 2x`"
        type="image/webp"
      />
      <source
        :srcset="`/img/pics/footer_${random}-1024w.jpg 1x, /img/pics/footer_${random}-1920w.jpg 2x`"
        type="image/jpeg"
      />
      <img
        :src="`/img/pics/footer_${random}-1024w.jpg`"
        alt=""
        width="5234"
        height="2189"
        loading="lazy"
      />
    </picture>
    <ul>
      <li>
        <b-select
          :aria-label="$t('Language')"
          v-if="$i18n"
          v-model="locale"
          :placeholder="$t('Select a language')"
        >
          <option
            v-for="(language, lang) in langs"
            :value="lang"
            :key="lang"
            :selected="isLangSelected(lang)"
          >
            {{ language }}
          </option>
        </b-select>
      </li>
      <li>
        <router-link :to="{ name: RouteName.ABOUT }">{{
          $t("About")
        }}</router-link>
      </li>
      <li>
        <router-link :to="{ name: RouteName.TERMS }">{{
          $t("Terms")
        }}</router-link>
      </li>
      <li>
        <a
          rel="external"
          hreflang="en"
          href="https://framagit.org/framasoft/mobilizon/blob/main/LICENSE"
        >
          {{ $t("License") }}
        </a>
      </li>
      <li>
        <a href="#navbar">{{ $t("Back to top") }}</a>
      </li>
    </ul>
    <div class="content has-text-centered">
      <i18n
        tag="span"
        path="Powered by {mobilizon}. © 2018 - {date} The Mobilizon Contributors - Made with the financial support of {contributors}."
      >
        <a rel="external" slot="mobilizon" href="https://joinmobilizon.org">{{
          $t("Mobilizon")
        }}</a>
        <span slot="date">{{ new Date().getFullYear() }}</span>
        <a
          rel="external"
          href="https://joinmobilizon.org/hall-of-fame"
          slot="contributors"
          >{{ $t("more than 1360 contributors") }}</a
        >
      </i18n>
    </div>
  </footer>
</template>
<script lang="ts">
import { Component, Vue, Watch } from "vue-property-decorator";
import { saveLocaleData } from "@/utils/auth";
import { loadLanguageAsync } from "@/utils/i18n";
import RouteName from "../router/name";
import langs from "../i18n/langs.json";

@Component
export default class Footer extends Vue {
  RouteName = RouteName;

  locale: string | null = this.$i18n.locale;

  langs: Record<string, string> = langs;

  // eslint-disable-next-line class-methods-use-this
  get random(): number {
    return Math.floor(Math.random() * 4) + 1;
  }

  @Watch("locale")
  // eslint-disable-next-line class-methods-use-this
  async updateLocale(locale: string): Promise<void> {
    if (locale) {
      console.debug("Setting locale from footer");
      await loadLanguageAsync(locale);
      saveLocaleData(locale);
    }
  }

  @Watch("$i18n.locale", { deep: true })
  updateLocaleFromI18n(locale: string): void {
    if (locale) {
      this.locale = locale;
    }
  }

  isLangSelected(lang: string): boolean {
    return lang === this.locale;
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
      max-width: 100%;
    }
  }

  div.content {
    flex: 1;
    padding-top: 10px;
  }

  ul {
    display: inline-flex;
    flex-wrap: wrap;
    justify-content: space-around;

    li {
      display: inline-flex;
      margin: auto 5px;
      padding: 2px 0;
      a {
        font-size: 1.1rem;
      }
    }
  }

  a {
    color: $white;
    text-decoration: underline;
    text-decoration-color: $secondary;

    &:focus {
      background-color: #000;
      color: #fff;
      outline: 3px solid #000;
      text-decoration: none;
    }
  }

  ::v-deep span.select {
    select,
    option {
      background: $background-color;
      color: $white;
    }
  }
}
</style>
