<template>
  <footer
    class="bg-violet-2 color-secondary flex flex-col items-center py-2 px-3"
    ref="footer"
  >
    <picture class="flex max-w-xl">
      <source
        :srcset="`/img/pics/footer_${random}-1024w.webp 1x, /img/pics/footer_${random}-1920w.webp 2x`"
        type="image/webp"
      />
      <img
        :src="`/img/pics/footer_${random}-1024w.webp`"
        alt=""
        width="1024"
        height="428"
        loading="lazy"
      />
    </picture>
    <ul
      class="inline-flex flex-wrap justify-around gap-3 text-lg text-white underline decoration-yellow-1"
    >
      <li>
        <o-select
          class="text-black dark:text-white"
          :aria-label="t('Language')"
          v-model="locale"
          :placeholder="t('Select a language')"
        >
          <option
            v-for="(language, lang) in langs"
            :value="lang"
            :key="lang"
            :selected="isLangSelected(lang)"
          >
            {{ language }}
          </option>
        </o-select>
      </li>
      <li>
        <router-link :to="{ name: RouteName.ABOUT }">{{
          t("About")
        }}</router-link>
      </li>
      <li>
        <router-link :to="{ name: RouteName.TERMS }">{{
          t("Terms")
        }}</router-link>
      </li>
      <li>
        <a
          rel="external"
          hreflang="en"
          href="https://framagit.org/framasoft/mobilizon/blob/main/LICENSE"
        >
          {{ t("License") }}
        </a>
      </li>
      <li>
        <a href="#navbar">{{ t("Back to top") }}</a>
      </li>
    </ul>
    <div class="text-center flex-1 pt-2 text-yellow-1">
      <i18n-t
        tag="span"
        keypath="Powered by {mobilizon}. © 2018 - {date} The Mobilizon Contributors - Made with the financial support of {contributors}."
      >
        <template #mobilizon>
          <a
            rel="external"
            class="text-white underline decoration-yellow-1"
            href="https://joinmobilizon.org"
            >{{ t("Mobilizon") }}</a
          >
        </template>
        <template #date
          ><span>{{ new Date().getFullYear() }}</span></template
        >
        <template #contributors>
          <a
            rel="external"
            class="text-white underline decoration-yellow-1"
            href="https://joinmobilizon.org/hall-of-fame"
            >{{ t("more than 1360 contributors") }}</a
          >
        </template>
      </i18n-t>
    </div>
  </footer>
</template>
<script setup lang="ts">
import { saveLocaleData } from "@/utils/auth";
import { loadLanguageAsync } from "@/utils/i18n";
import RouteName from "../router/name";
import langs from "../i18n/langs.json";
import { computed, watch } from "vue";
import { useI18n } from "vue-i18n";

const { locale, t } = useI18n({ useScope: "global" });

const random = computed((): number => {
  return Math.floor(Math.random() * 4) + 1;
});

watch(locale, async () => {
  if (locale) {
    console.debug("Setting locale from footer");
    await loadLanguageAsync(locale.value as string);
    saveLocaleData(locale.value as string);
  }
});

const isLangSelected = (lang: string): boolean => {
  return lang === locale.value;
};
</script>
