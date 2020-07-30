// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from "vue";
import Buefy from "buefy";
import Component from "vue-class-component";
import VueScrollTo from "vue-scrollto";
import VueMeta from "vue-meta";
import VTooltip from "v-tooltip";
import TimeAgo from "javascript-time-ago";
import App from "./App.vue";
import router from "./router";
import { NotifierPlugin } from "./plugins/notifier";
import filters from "./filters";
import { i18n } from "./utils/i18n";
import messages from "./i18n";
import apolloProvider from "./vue-apollo";

Vue.config.productionTip = false;

let language = document.documentElement.getAttribute("lang") as string;
language =
  language ||
  ((window.navigator as any).userLanguage || window.navigator.language).replace(/-/, "_");
export const locale =
  language && messages.hasOwnProperty(language) ? language : language.split("-")[0];

import(`javascript-time-ago/locale/${locale}`).then((localeFile) => {
  TimeAgo.addLocale(localeFile);
  Vue.prototype.$timeAgo = new TimeAgo(locale);
});

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
  i18n,
});
