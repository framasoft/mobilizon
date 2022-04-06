import Vue from "vue";
import VueMatomo from "vue-matomo";

export const matomo = (environment: any, matomoConfiguration: any) => {
  console.debug("Loading Matomo statistics");
  console.debug(
    "Calling VueMatomo with the following configuration",
    matomoConfiguration
  );
  Vue.use(VueMatomo, {
    ...matomoConfiguration,
    router: environment.router,
  });
};
