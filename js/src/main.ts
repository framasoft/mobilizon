// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
// import * as VueGoogleMaps from 'vue2-google-maps';
import VueMarkdown from 'vue-markdown';
import Buefy from 'buefy'
import 'buefy/dist/buefy.css';
import GetTextPlugin from 'vue-gettext';
import App from '@/App.vue';
import router from '@/router';
import { apolloProvider } from './vue-apollo';

const translations = require('@/i18n/translations.json');

Vue.config.productionTip = false;

Vue.use(VueMarkdown);
Vue.use(Buefy, {
  defaultContainerElement: '#mobilizon'
});

const language = (window.navigator as any).userLanguage || window.navigator.language;

Vue.filter('formatDate', value => value ? new Date(value).toLocaleString() : null);
Vue.filter('formatDay', value => value ? new Date(value).toLocaleDateString() : null);

Vue.use(GetTextPlugin, {
  translations,
  defaultLanguage: 'en_US',
});

Vue.config.language = language.replace('-', '_');

/* eslint-disable no-new */
new Vue({
  router,
  el: '#app',
  template: '<App/>',
  apolloProvider,
  components: { App },
});
