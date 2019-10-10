// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
import Buefy from 'buefy';
import VueI18n from 'vue-i18n';
import Component from 'vue-class-component';
import App from '@/App.vue';
import router from '@/router';
import { apolloProvider } from './vue-apollo';
import { NotifierPlugin } from '@/plugins/notifier';
import filters from '@/filters';
import messages from '@/i18n/index';
import VueMeta from 'vue-meta';

Vue.config.productionTip = false;

Vue.use(Buefy);
Vue.use(NotifierPlugin);
Vue.use(filters);
Vue.use(VueMeta);

const language = (window.navigator as any).userLanguage || window.navigator.language;

Vue.use(VueI18n);

const i18n = new VueI18n({
  locale: language.replace('-', '_'), // set locale
  messages, // set locale messages
});

// Register the router hooks with their names
Component.registerHooks([
  'beforeRouteEnter',
  'beforeRouteLeave',
  'beforeRouteUpdate', // for vue-router 2.2+
]);

/* eslint-disable no-new */
new Vue({
  router,
  apolloProvider,
  el: '#app',
  template: '<App/>',
  components: { App },
  i18n,
});
