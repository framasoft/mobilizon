// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
import Buefy from 'buefy';
import GetTextPlugin from 'vue-gettext';
import App from '@/App.vue';
import router from '@/router';
import { apolloProvider } from './vue-apollo';
import { NotifierPlugin } from '@/plugins/notifier';

const translations = require('@/i18n/translations.json');

Vue.config.productionTip = false;

Vue.use(Buefy);
Vue.use(NotifierPlugin);

const language = (window.navigator as any).userLanguage || window.navigator.language;

Vue.use(GetTextPlugin, {
  translations,
  defaultLanguage: 'en_US',
});

Vue.config.language = language.replace('-', '_');

/* eslint-disable no-new */
new Vue({
  router,
  apolloProvider,
  el: '#app',
  template: '<App/>',
  components: { App },
});
