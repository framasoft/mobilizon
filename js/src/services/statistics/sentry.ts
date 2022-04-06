import Vue from "vue";

import * as Sentry from "@sentry/vue";
import { Integrations } from "@sentry/tracing";

export const sentry = (environment: any, sentryConfiguration: any) => {
  console.debug("Loading Sentry statistics");
  console.debug(
    "Calling Sentry with the following configuration",
    sentryConfiguration
  );
  // Don't attach errors to previous events
  window.sessionStorage.removeItem("lastEventId");
  Sentry.init({
    Vue,
    dsn: sentryConfiguration.dsn,
    integrations: [
      new Integrations.BrowserTracing({
        routingInstrumentation: Sentry.vueRouterInstrumentation(
          environment.router
        ),
        tracingOrigins: ["localhost", "mobilizon1.com", /^\//],
      }),
    ],
    beforeSend(event) {
      // Check if it is an exception, and if so, save it in session storage
      // so that it can be retreived from the error component
      if (event.exception && event.event_id) {
        window.sessionStorage.setItem("lastEventId", event.event_id);
      }
      return event;
    },
    // Set tracesSampleRate to 1.0 to capture 100%
    // of transactions for performance monitoring.
    // We recommend adjusting this value in production
    tracesSampleRate: sentryConfiguration.tracesSampleRate,
    release: environment.version,
  });
};

export const submitFeedback = async (
  endpoint: string,
  dsn: string,
  params: Record<string, string>
): Promise<void> => {
  await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-type": "application/json",
      Authorization: `DSN ${dsn}`,
    },
    body: JSON.stringify(params),
  });
};
