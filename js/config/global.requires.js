import Vue from 'vue';
import VueI18n from 'vue-i18n';
import Buefy from 'buefy';
import 'bulma/css/bulma.min.css';
import 'buefy/dist/buefy.min.css';
import filters from '@/filters';

Vue.use(VueI18n);
Vue.use(Buefy);
Vue.use(filters);

Vue.component('router-link', {
    props: {
      tag: { type: String, default: 'a' }
    },
    render(createElement) {
      return createElement(this.tag, {}, this.$slots.default)
    }
});
