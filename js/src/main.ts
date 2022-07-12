import { provide, createApp, h } from "vue";
// import "../node_modules/bulma/css/bulma.min.css";
import VueScrollTo from "vue-scrollto";
// import VueAnnouncer from "@vue-a11y/announcer";
// import VueSkipTo from "@vue-a11y/skip-to";
import App from "./App.vue";
import { router } from "./router";
import { i18n, locale } from "./utils/i18n";
import { apolloClient } from "./vue-apollo";
import Breadcrumbs from "@/components/Utils/Breadcrumbs.vue";
import { DefaultApolloClient } from "@vue/apollo-composable";
import "./registerServiceWorker";
import "./assets/tailwind.css";
import { setAppForAnalytics } from "./services/statistics";
import Button from "./components/core/Button.vue";
import Message from "./components/core/Message.vue";
import CoreInput from "./components/core/Input.vue";
import CoreField from "./components/core/Field.vue";
import { dateFnsPlugin } from "./plugins/dateFns";
import { dialogPlugin } from "./plugins/dialog";
import { snackbarPlugin } from "./plugins/snackbar";
import { notifierPlugin } from "./plugins/notifier";
import Tag from "./components/core/Tag.vue";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import Oruga from "@oruga-ui/oruga-next";
// import "@oruga-ui/oruga-next/dist/oruga-full-vars.css";
import "@oruga-ui/oruga-next/dist/oruga.css";
import "./assets/oruga-tailwindcss.css";
import { orugaConfig } from "./oruga-config";
import MaterialIcon from "./components/core/MaterialIcon.vue";
import { createHead } from "@vueuse/head";

// Vue.use(VueScrollTo);
// Vue.use(VueAnnouncer);
// Vue.use(VueSkipTo);

// const app = createApp(App);

const head = createHead();

const app = createApp({
  setup() {
    provide(DefaultApolloClient, apolloClient);
  },
  render: () => h(App),
});
// app.provide(DefaultApolloClient, apolloClient);

app.use(router);
app.use(i18n);
app.use(dateFnsPlugin, { locale });
app.use(dialogPlugin);
app.use(snackbarPlugin);
app.use(notifierPlugin);
app.use(VueScrollTo);
app.use(FloatingVue);
app.use(head);
app.component("breadcrumbs-nav", Breadcrumbs);
app.component("b-button", Button);
app.component("b-message", Message);
app.component("b-input", CoreInput);
app.component("b-field", CoreField);
app.component("b-tag", Tag);
app.component("material-icon", MaterialIcon);
app.use(Oruga, orugaConfig);

app.mount("#app");

setAppForAnalytics(app);
