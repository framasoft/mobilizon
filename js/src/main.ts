// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
import Buefy from 'buefy';
import Component from 'vue-class-component';
import App from '@/App.vue';
import router from '@/router';
import { apolloProvider } from './vue-apollo';
import { NotifierPlugin } from '@/plugins/notifier';
import filters from '@/filters';
import VueMeta from 'vue-meta';
import { i18n } from '@/utils/i18n';

Vue.config.productionTip = false;

Vue.use(Buefy);
Vue.use(NotifierPlugin);
Vue.use(filters);
Vue.use(VueMeta);

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
