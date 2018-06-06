import { API_ORIGIN, API_PATH } from './_entrypoint';

const jsonLdMimeType = 'application/json';

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

  const link = url.includes(API_PATH) ? API_ORIGIN + url : API_ORIGIN + API_PATH + url;

  return fetch(link, options).then((response) => {
    if (response.ok) return response;

    throw response.text();
  });
}
