import VueI18n from 'vue-i18n'
import messages from '@/i18n/index';

const language = (window.navigator).userLanguage || window.navigator.language;
const i18n = new VueI18n({
    locale: language.replace('-', '_'), // set locale
    messages, // set locale messages
  });

  export default previewComponent => {
    // https://vuejs.org/v2/guide/render-function.html
    return {
      i18n,
      render(createElement) {
        return createElement(previewComponent)
      }
    }
  }