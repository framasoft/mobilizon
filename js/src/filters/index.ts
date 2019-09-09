import { formatDateString, formatTimeString, formatDateTimeString } from './datetime';

export default {
  install(vue) {
    vue.filter('formatDateString', formatDateString);
    vue.filter('formatTimeString', formatTimeString);
    vue.filter('formatDateTimeString', formatDateTimeString);
  },
};
