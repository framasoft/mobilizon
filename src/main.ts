import { provide, createApp, h, ref } from "vue";
import VueScrollTo from "vue-scrollto";
// import VueAnnouncer from "@vue-a11y/announcer";
// import VueSkipTo from "@vue-a11y/skip-to";
import App from "./App.vue";
import { router } from "./router";
import { i18n, locale } from "./utils/i18n";
import { apolloClient } from "./vue-apollo";
import Breadcrumbs from "@/components/Utils/NavBreadcrumbs.vue";
import { DefaultApolloClient } from "@vue/apollo-composable";
import "./registerServiceWorker";
import "./assets/tailwind.css";
import { setAppForAnalytics } from "./services/statistics";
import { dateFnsPlugin } from "./plugins/dateFns";
import { dialogPlugin } from "./plugins/dialog";
import { snackbarPlugin } from "./plugins/snackbar";
import { notifierPlugin } from "./plugins/notifier";
import FloatingVue from "floating-vue";
import "floating-vue/dist/style.css";
import Oruga from "@oruga-ui/oruga-next";
import "@oruga-ui/theme-oruga/dist/oruga.css";
import "./assets/oruga-tailwindcss.css";
import { orugaConfig } from "./oruga-config";
import MaterialIcon from "./components/core/MaterialIcon.vue";
import { createHead } from "@unhead/vue";
import { CONFIG } from "./graphql/config";
import { IConfig } from "./types/config.model";

// Vue.use(VueAnnouncer);
// Vue.use(VueSkipTo);

const app = createApp({
  setup() {
    provide(DefaultApolloClient, apolloClient);
  },
  render: () => h(App),
});

app.use(router);
app.use(i18n);
app.use(dateFnsPlugin, { locale });
app.use(dialogPlugin);
app.use(snackbarPlugin);
app.use(notifierPlugin);
app.use(VueScrollTo);
app.use(FloatingVue);

app.component("breadcrumbs-nav", Breadcrumbs);
app.component("material-icon", MaterialIcon);
app.use(Oruga, orugaConfig);

const instanceName = ref<string>();

apolloClient
  .query<{ config: IConfig }>({
    query: CONFIG,
  })
  .then(({ data: configData }) => {
    instanceName.value = configData.config?.name;

    const primaryColor = configData.config?.primaryColor;
    if (primaryColor) {
      document.documentElement.style.setProperty(
        "--custom-primary",
        primaryColor
      );
    }
    const secondaryColor = configData.config?.secondaryColor;
    if (secondaryColor) {
      document.documentElement.style.setProperty(
        "--custom-secondary",
        secondaryColor
      );
    }
  });

const head = createHead();
app.use(head);

app.mount("#app");

setAppForAnalytics(app);
