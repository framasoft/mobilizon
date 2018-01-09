import router from '../router/index';
import { API_HOST, API_PATH } from '../api/_entrypoint';

// URL and endpoint constants
const LOGIN_URL = `${API_HOST}${API_PATH}/login`;
const SIGNUP_URL = `${API_HOST}${API_PATH}/users/`;
const CHECK_AUTH = `${API_HOST}${API_PATH}/users/`;
const REFRESH_TOKEN = `${API_HOST}${API_PATH}/token/refresh`;

function AuthError(field, message) {
  this.field = field;
  this.message = message;
}

AuthError.prototype.toString = function AuthErrorToString() {
  return `AuthError: ${this.message}`;
};

export default {

  // User object will let us check authentication status
  user: false,
  authenticated: false,
  token: false,

  // Send a request to the login URL and save the returned JWT
  login(creds, $store, redirect, error) {
    fetch(LOGIN_URL, { method: 'POST', body: creds, headers: { 'Content-Type': 'application/json' } })
      .then(response => response.json())
      .then((data) => {
        if (data.code >= 300) {
          throw new AuthError(null, data.message);
        }
        $store.commit('LOGIN_USER');

        localStorage.setItem('token', data.token);
        localStorage.setItem('refresh_token', data.refresh_token);
        this.getUser(
          $store,
          () => router.push(redirect)
        );

      }).catch((err) => {
        error(err);
      });
  },

  signup(creds, $store, redirect, error) {
    fetch(SIGNUP_URL, { method: 'POST', body: creds, headers: { 'Content-Type': 'application/json' } })
      .then(response => response.json())
      .then((data) => {
        if (data.error) {
          throw new AuthError(data.error.field, data.error.message);
        }

        $store.commit('LOGIN_USER');
        localStorage.setItem('token', data.token);
        localStorage.setItem('refresh_token', data.refresh_token);

        if (redirect) {
          router.push(redirect);
        }
      }).catch((err) => {
        error(err);
      });
  },
  refreshToken(store, successHandler, errorHandler) {
    const refreshToken = localStorage.getItem('refresh_token');
    console.log("We are refreshing the jwt token");
    fetch(REFRESH_TOKEN, { method: 'POST', body: JSON.stringify({refresh_token: refreshToken}), headers: { 'Content-Type': 'application/json' }})
      .then((response) => {
        if (response.ok) {
          return response.json();
        } else {
          errorHandler('Error while authenticating');
        }
      })
      .then((response) => {
        console.log("We have a new token");
        this.authenticated = true;
        store.commit('LOGIN_USER', response);
        localStorage.setItem('token', response.token);
        console.log("Let's try to auth again");
        this.getUser(store, successHandler, errorHandler);
        successHandler();
      });
  },

  // To log out, we just need to remove the token
  logout() {
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('token');
    this.authenticated = false;
  },

  jwt_decode(token) {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace('-', '+').replace('_', '/');
    return JSON.parse(window.atob(base64));
  },

  getTokenExpirationDate(encodedToken) {
    const token = this.jwt_decode(encodedToken);
    if (!token.exp) { return null; }

    const date = new Date(0);
    date.setUTCSeconds(token.exp);

    return date;
  },

  isTokenExpired(token) {
    const expirationDate = this.getTokenExpirationDate(token);
    return expirationDate < new Date();
  },

  checkAuth(store = null) {
    const token = localStorage.getItem('token');
    if (store && token) {
      this.getUser(store,() => null, () => null);
    }
    /* if (!!token && store && !this.isTokenExpired(token)) {
      this.refreshToken(store, () => null, () => null);
    } */
    return !!token;
  },

  getUser(store, successHandler, errorHandler) {
    console.log("We are checking the auth");
    this.token = localStorage.getItem('token');
    const options = {};
    options.headers = new Headers();
    options.headers.set('Authorization', `Bearer ${this.token}`);
    fetch(CHECK_AUTH, options)
      .then((response) => {
        if (response.ok) {
          return response.json();
        } else {
          errorHandler('Error while authenticating');
        }
      })
      .then((response) => {
        this.authenticated = true;
        console.log(response);
        store.commit('SAVE_USER', response);
        successHandler();
      });
  },

  // The object to be passed as a header for authenticated requests
  getAuthHeader() {
    return {
      Authorization: `Bearer ${localStorage.getItem('access_token')}`,
    };
  },
};
