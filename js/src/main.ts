// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from "vue";
import Buefy from "buefy";
import Component from "vue-class-component";
import VueScrollTo from "vue-scrollto";
import VueMeta from "vue-meta";
import VTooltip from "v-tooltip";
import App from "./App.vue";
import router from "./router";
import { NotifierPlugin } from "./plugins/notifier";
import filters from "./filters";
import { i18n } from "./utils/i18n";
import apolloProvider from "./vue-apollo";
import "./registerServiceWorker";

Vue.config.productionTip = false;

Vue.use(Buefy);
Vue.use(NotifierPlugin);
Vue.use(filters);
Vue.use(VueMeta);
Vue.use(VueScrollTo);
Vue.use(VTooltip);

// Register the router hooks with their names
Component.registerHooks([
  "beforeRouteEnter",
  "beforeRouteLeave",
  "beforeRouteUpdate", // for vue-router 2.2+
]);

/* eslint-disable no-new */
new Vue({
  router,
  apolloProvider,
  el: "#app",
  template: "<App/>",
  components: { App },
  render: (h) => h(App),
  i18n,
});
