import { API_ORIGIN, API_PATH } from '../api/_entrypoint';
import { LOGIN_USER, LOAD_USER, CHANGE_ACTOR } from '../store/mutation-types';

// URL and endpoint constants
const LOGIN_URL = `${API_ORIGIN}${API_PATH}/login`;
const SIGNUP_URL = `${API_ORIGIN}${API_PATH}/users/`;
const CHECK_AUTH = `${API_ORIGIN}${API_PATH}/user/`;
const REFRESH_TOKEN = `${API_ORIGIN}${API_PATH}/token/refresh`;

export default {

  // Send a request to the login URL and save the returned JWT
  login(creds, success, error) {
    fetch(LOGIN_URL, { method: 'POST', body: creds, headers: { 'Content-Type': 'application/json' } })
      .then((response) => {
        if (response.status === 200) {
          return response.json();
        }
        throw response.json();
      })
      .then((data) => {
        localStorage.setItem('token', data.token);
        // localStorage.setItem('refresh_token', data.refresh_token);
        return success(data);
      })
      .catch(err => error(err));
  },

  signup(creds, success, error) {
    fetch(SIGNUP_URL, { method: 'POST', body: creds, headers: { 'Content-Type': 'application/json' } })
      .then((response) => {
        if (response.status === 200) {
          return response.json();
        }
        throw response.json();
      })
      .then((data) => {
        localStorage.setItem('token', data.token);
        // localStorage.setItem('refresh_token', data.refresh_token);

        return success(data);
      }).catch(err => error(err));
  },
  refreshToken(store, successHandler, errorHandler) {
    const refreshToken = localStorage.getItem('refresh_token');
    console.log('We are refreshing the jwt token');
    fetch(REFRESH_TOKEN, { method: 'POST', body: JSON.stringify({ refresh_token: refreshToken }), headers: { 'Content-Type': 'application/json' } })
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        return errorHandler('Error while authenticating');
      })
      .then((response) => {
        console.log('We have a new token');
        this.authenticated = true;
        store.commit(LOGIN_USER, response);
        localStorage.setItem('token', response.token);
        console.log("Let's try to auth again");
        successHandler();
      });
  },

  // To log out, we just need to remove the token
  logout(store) {
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('token');
    this.authenticated = false;
    store.commit('LOGOUT_USER');
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

  getUser(store, successHandler, errorHandler) {
    console.log('We are checking the auth');
    this.token = localStorage.getItem('token');
    const options = {};
    options.headers = new Headers();
    options.headers.set('Authorization', `Bearer ${this.token}`);
    fetch(CHECK_AUTH, options)
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        return errorHandler('Error while authenticating');
      }).then((response) => {
        this.authenticated = true;
        console.log(response);
        store.commit(LOAD_USER, response.data);
        store.commit(CHANGE_ACTOR, response.data.actors[0]);
        return successHandler();
      });
  },

  // The object to be passed as a header for authenticated requests
  getAuthHeader() {
    return {
      Authorization: `Bearer ${localStorage.getItem('access_token')}`,
    };
  },
};
