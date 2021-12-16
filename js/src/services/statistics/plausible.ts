import VueRouter from "vue-router";
import Vue from "vue";
import { VuePlausible } from "vue-plausible";
export default (router: VueRouter, plausibleConfiguration: any) => {
  console.debug("Loading Plausible statistics");

  Vue.use(VuePlausible, {
    // see configuration section
    ...plausibleConfiguration,
  });
};
