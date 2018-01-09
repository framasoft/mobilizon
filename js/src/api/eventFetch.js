import { API_HOST, API_PATH } from './_entrypoint';

const jsonLdMimeType = 'application/ld+json';

export default function eventFetch(url, store, optionsarg = {}) {
  const options = optionsarg;
  if (typeof options.headers === 'undefined') {
    options.headers = new Headers();
  }
  if (options.headers.get('Accept') === null) {
    options.headers.set('Accept', jsonLdMimeType);
  }

  if (options.body !== 'undefined' && !(options.body instanceof FormData) && options.headers.get('Content-Type') === null) {
    options.headers.set('Content-Type', jsonLdMimeType);
  }

  if (store.state.user) {
    options.headers.set('Authorization', `Bearer ${localStorage.getItem('token')}`);
  }

  const link = url.includes(API_PATH) ? API_HOST + url : API_HOST + API_PATH + url;

  return fetch(link, options).then((response) => {
    if (response.ok) return response;

    return response
      .json()
      .then((json) => {
        const error = json['hydra:description'] ? json['hydra:description'] : response.statusText;
        if (!json.violations) throw Error(error);

        // const errors = { _error: error };
        // json.violations.map(violation => errors[violation.propertyPath] = violation.message);

        // throw errors;
      });
  });
}
