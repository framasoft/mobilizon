// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
// import * as VueGoogleMaps from 'vue2-google-maps';
import VueMarkdown from 'vue-markdown';
import Vuetify from 'vuetify';
import moment from 'moment';
import GetTextPlugin from 'vue-gettext';
import 'material-design-icons/iconfont/material-icons.css';
import 'vuetify/dist/vuetify.min.css';
import App from '@/App.vue';
import router from '@/router';
// import store from './store';
import { createProvider } from './vue-apollo';

const translations = require('@/i18n/translations.json');

Vue.config.productionTip = false;

Vue.use(VueMarkdown);
Vue.use(Vuetify);

const language = (window.navigator as any).userLanguage || window.navigator.language;
moment.locale(language);

Vue.filter('formatDate', value => (value ? moment(String(value)).format('LLLL') : null));
Vue.filter('formatDay', value => (value ? moment(String(value)).format('LL') : null));

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
  apolloProvider: createProvider(),
  components: { App },
});
