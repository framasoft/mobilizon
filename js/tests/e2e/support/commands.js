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
// Cypress.Commands.add("drag", { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add("dismiss", { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This is will overwrite an existing command --
// Cypress.Commands.overwrite("visit", (originalFn, url, options) => { ... })

let LOCAL_STORAGE_MEMORY = {};

Cypress.Commands.add("saveLocalStorage", () => {
    Object.keys(localStorage).forEach(key => {
        LOCAL_STORAGE_MEMORY[key] = localStorage[key];
    });
});

Cypress.Commands.add("restoreLocalStorage", () => {
    Object.keys(LOCAL_STORAGE_MEMORY).forEach(key => {
        localStorage.setItem(key, LOCAL_STORAGE_MEMORY[key]);
    });
});

Cypress.Commands.add('checkoutSession', async () => {
    const response = await fetch('/sandbox', {
        cache: 'no-store',
        method: 'POST',
    });

    const sessionId = await response.text();
    return Cypress.env('sessionId', sessionId);
});

Cypress.Commands.add('dropSession', () =>
  cy.waitForFetches().then(() =>
    fetch('/sandbox', {
      method: 'DELETE',
      headers: { 'x-session-id': Cypress.env('sessionId') },
    }),
  ),
);



const increaseFetches = () => {
    const count = Cypress.env('fetchCount') || 0;
    Cypress.env('fetchCount', count + 1);
  };
  
  const decreaseFetches = () => {
    const count = Cypress.env('fetchCount') || 0;
    Cypress.env('fetchCount', count - 1);
  };
  
  const buildTrackableFetchWithSessionId = fetch => (fetchUrl, fetchOptions) => {
    const { headers } = fetchOptions;
    const modifiedHeaders = Object.assign(
      { 'x-session-id': Cypress.env('sessionId') },
      headers,
    );
  
    const modifiedOptions = Object.assign({}, fetchOptions, {
      headers: modifiedHeaders,
    });
  
    return fetch(fetchUrl, modifiedOptions)
      .then(result => {
        decreaseFetches();
        return Promise.resolve(result);
      })
      .catch(result => {
        decreaseFetches();
        return Promise.reject(result);
      });
  };
  
  Cypress.on('window:before:load', win => {
    cy.stub(win, 'fetch', buildTrackableFetchWithSessionId(fetch));
  });
  
  Cypress.Commands.add('waitForFetches', () => {
    if (Cypress.env('fetchCount') <= 0) {
      return;
    }
  
    cy.wait(100).then(() => cy.waitForFetches());
  });

  Cypress.Commands.add(
    'iframeLoaded',
    { prevSubject: 'element' },
    ($iframe) => {
      const contentWindow = $iframe.prop('contentWindow')
      return new Promise(resolve => {
        if (
          contentWindow &&
          contentWindow.document.readyState === 'complete'
        ) {
          resolve(contentWindow)
        } else {
          $iframe.on('load', () => {
            resolve(contentWindow)
          })
        }
      })
    })
  
  Cypress.Commands.add(
    'getInDocument',
    { prevSubject: 'document' },
    (document, selector) => Cypress.$(selector, document)
  )