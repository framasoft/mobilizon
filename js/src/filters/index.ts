import { formatDateString, formatTimeString, formatDateTimeString } from './datetime';
import { nl2br } from '@/filters/utils';

export default {
  install(vue) {
    vue.filter('formatDateString', formatDateString);
    vue.filter('formatTimeString', formatTimeString);
    vue.filter('formatDateTimeString', formatDateTimeString);
    vue.filter('nl2br', nl2br);
  },
};
