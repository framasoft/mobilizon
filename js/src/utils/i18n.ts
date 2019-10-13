import Vue from 'vue';
import VueI18n from 'vue-i18n';
import messages from '@/i18n/index';

const language = (window.navigator as any).userLanguage || window.navigator.language;

Vue.use(VueI18n);

export const i18n = new VueI18n({
  locale: language.split('-')[0], // set locale
  messages, // set locale messages
  fallbackLocale: 'en_US',
});
