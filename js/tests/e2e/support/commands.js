// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add("login", (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add("drag",
// { prevSubject: 'element' }, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss",
// { prevSubject: 'optional' }, (subject, options) => { ... })
//
//
// -- This is will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

const AUTH_ACCESS_TOKEN = "auth-access-token";
const AUTH_REFRESH_TOKEN = "auth-refresh-token";
const AUTH_USER_ID = "auth-user-id";
const AUTH_USER_EMAIL = "auth-user-email";
const AUTH_USER_ACTOR_ID = "auth-user-actor-id";
const AUTH_USER_ROLE = "auth-user-role";

const LOCAL_STORAGE_MEMORY = {};

Cypress.Commands.add("saveLocalStorage", () => {
  Object.keys(localStorage).forEach((key) => {
    LOCAL_STORAGE_MEMORY[key] = localStorage[key];
  });
});

Cypress.Commands.add("restoreLocalStorage", () => {
  Object.keys(LOCAL_STORAGE_MEMORY).forEach((key) => {
    localStorage.setItem(key, LOCAL_STORAGE_MEMORY[key]);
  });
});

Cypress.Commands.add("clearLocalStorage", () => {
  Object.keys(LOCAL_STORAGE_MEMORY).forEach((key) => {
    localStorage.removeItem(key);
  });
});

Cypress.Commands.add("loginUser", () => {
  console.log("Going to login an user");
  const loginMutation = `
    mutation Login($email: String!, $password: String!) {
      login(email: $email, password: $password) {
        accessToken,
        refreshToken,
        user {
          id,
          email,
          role
        }
      },
    }`;

  const body = JSON.stringify({
    operationName: "Login",
    query: loginMutation,
    variables: { email: "user@email.com", password: "some password" },
  });

  cy.request({
    url: "http://localhost:4000/api",
    body,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
  }).then((res) => {
    console.log("Reply from server when logging-in", res);
    const obj = res.body.data.login;
    console.log("Login data: ", obj);

    localStorage.setItem(AUTH_USER_ID, `${obj.user.id}`);
    localStorage.setItem(AUTH_USER_EMAIL, obj.user.email);
    localStorage.setItem(AUTH_USER_ROLE, obj.user.role);

    localStorage.setItem(AUTH_USER_ACTOR_ID, `${obj.id}`);
    localStorage.setItem(AUTH_ACCESS_TOKEN, obj.accessToken);
    localStorage.setItem(AUTH_REFRESH_TOKEN, obj.refreshToken);
  });
});

// const increaseFetches = () => {
//   const count = Cypress.env('fetchCount') || 0;
//   Cypress.env('fetchCount', count + 1);
// };

const decreaseFetches = () => {
  const count = Cypress.env("fetchCount") || 0;
  Cypress.env("fetchCount", count - 1);
};

const buildTrackableFetchWithSessionId =
  (fetch) => (fetchUrl, fetchOptions) => {
    const { headers } = fetchOptions;
    const modifiedHeaders = {
      "x-session-id": Cypress.env("sessionId"),
      ...headers,
    };

    const modifiedOptions = { ...fetchOptions, headers: modifiedHeaders };

    return fetch(fetchUrl, modifiedOptions)
      .then((result) => {
        decreaseFetches();
        return Promise.resolve(result);
      })
      .catch((result) => {
        decreaseFetches();
        return Promise.reject(result);
      });
  };

Cypress.on("window:before:load", (win) => {
  cy.stub(win, "fetch", buildTrackableFetchWithSessionId(fetch));
});

Cypress.Commands.add("waitForFetches", () => {
  if (Cypress.env("fetchCount") <= 0) {
    return;
  }

  cy.waitForFetches();
});

Cypress.Commands.add("iframeLoaded", { prevSubject: "element" }, ($iframe) => {
  const contentWindow = $iframe.prop("contentWindow");
  return new Promise((resolve) => {
    if (contentWindow && contentWindow.document.readyState === "complete") {
      resolve(contentWindow);
    } else {
      $iframe.on("load", () => {
        resolve(contentWindow);
      });
    }
  });
});

Cypress.Commands.add(
  "getInDocument",
  { prevSubject: "document" },
  (document, selector) => Cypress.$(selector, document)
);
