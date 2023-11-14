import { VuePlausible } from "vue-plausible";
export default (environment: any, plausibleConfiguration: any) => {
  console.debug("Loading Plausible statistics");

  environment.app.use(VuePlausible, {
    // see configuration section
    ...plausibleConfiguration,
  });
};
