// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
// import * as VueGoogleMaps from 'vue2-google-maps';
import VueMarkdown from 'vue-markdown';
import Vuetify from 'vuetify';
import moment from 'moment';
import VuexI18n from 'vuex-i18n';
import 'material-design-icons/iconfont/material-icons.css';
import 'vuetify/dist/vuetify.min.css';
import App from './App.vue';
import router from './router';
import store from './store';
import translations from './i18n';
import auth from './auth';

Vue.config.productionTip = false;

Vue.use(VueMarkdown);
Vue.use(Vuetify);
let language = window.navigator.userLanguage || window.navigator.language;
moment.locale(language);

Vue.filter('formatDate', value => (value ? moment(String(value)).format('LLLL') : null));
Vue.filter('formatDay', value => (value ? moment(String(value)).format('LL') : null));

if (!(language in translations)) {
  [language] = language.split('-', 1);
}

Vue.use(VuexI18n.plugin, store);

Object.entries(translations).forEach((key) => {
  Vue.i18n.add(key[0], key[1]);
});

Vue.i18n.set(language);
Vue.i18n.fallback('en');

router.beforeEach((to, from, next) => {
  if (to.matched.some(record => record.meta.requiredAuth) && !store.state.user) {
    next({
      name: 'Login',
      query: { redirect: to.fullPath },
    });
  } else {
    next();
  }
});

auth.getUser(store, () => {}, (error) => {
  console.warn(error);
});

console.log('store', store);

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  store,
  template: '<App/>',
  components: { App },
});
