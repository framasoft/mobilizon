import { LOGIN_USER, LOGOUT_USER, LOAD_USER } from './mutation-types';

const state = {
  isLogged: !!localStorage.getItem('token'),
  user: false,
};

/* eslint-disable */
const mutations = {
  [LOGIN_USER](state, user) {
    state.isLogged = true;
    state.user = user;
  },

  [LOAD_USER](state, user) {
    state.user = user;
  },

  [LOGOUT_USER](state) {
    state.isLogged = false;
    state.user = null;
  },
};
/* eslint-enable */

export default { state, mutations };
