// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue';
// import * as VueGoogleMaps from 'vue2-google-maps';
import VueMarkdown from 'vue-markdown';
import VuetifyGoogleAutocomplete from 'vuetify-google-autocomplete';
import Vuetify from 'vuetify';
import Vuex from 'vuex';
import moment from 'moment';
import VuexI18n from 'vuex-i18n';
import 'vuetify/dist/vuetify.min.css';
import 'material-design-icons-iconfont/dist/material-design-icons.css';
import App from '@/App';
import router from '@/router';
import storeData from '@/store/index';
import translations from '@/i18n/index';
import auth from '@/auth';

Vue.config.productionTip = false;

Vue.use(VuetifyGoogleAutocomplete, {
    apiKey: 'AIzaSyBF37pw38j0giICt73TCAPNogc07Upe_Q4', // Can also be an object. E.g, for Google Maps Premium API, pass `{ client: <YOUR-CLIENT-ID> }`
});

/*Vue.use(VueGoogleMaps, {
  load: {
    key: 'AIzaSyBF37pw38j0giICt73TCAPNogc07Upe_Q4',
    libraries: 'places',
    installComponents: false,
  },
});*/

Vue.use(VueMarkdown);
Vue.use(Vuetify);
Vue.use(Vuex);
let language = window.navigator.userLanguage || window.navigator.language;
moment.locale(language);

Vue.filter('formatDate', value => (value ? moment(String(value)).format('LLLL') : null));

if (!(language in translations)) {
  [language] = language.split('-', 1);
}

const store = new Vuex.Store(storeData);

Vue.use(VuexI18n.plugin, store);

Object.entries(translations).forEach((key) => {
  Vue.i18n.add(key[0], key[1]);
});

Vue.i18n.set(language);
Vue.i18n.fallback('en');

router.beforeEach((to, from, next) => {
  if (to.matched.some(record => record.meta.requiredAuth) && store.state.user === undefined || store.state.user == null) {
    next({
      name: 'Login',
      query: { redirect: to.fullPath }
    });
  } else {
    next();
  }
});

auth.getUser(store, () => {}, () => {});

/* eslint-disable no-new */
new Vue({
  el: '#app',
  router,
  store,
  template: '<App/>',
  components: { App },
});
