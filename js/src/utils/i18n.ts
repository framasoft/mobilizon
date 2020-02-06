import Vue from 'vue';
import VueI18n from 'vue-i18n';
import messages from '@/i18n/index';

const language = ((window.navigator as any).userLanguage || window.navigator.language).replace(/-/, '_');
const locale = messages.hasOwnProperty(language) ? language : language.split('-')[0];

Vue.use(VueI18n);

export const i18n = new VueI18n({
  locale, // set locale
  messages, // set locale messages
  fallbackLocale: 'en_US',
});
