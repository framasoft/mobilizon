import { LOGIN_USER, LOGOUT_USER, SAVE_USER } from './mutation-types';

const state = {
  isLogged: !!localStorage.getItem('token'),
  user: false,
};

const mutations = {
  [LOGIN_USER](state) {
    state.isLogged = true;
  },

  [LOGOUT_USER](state) {
    state.isLogged = false;
  },
  [SAVE_USER](state, user) {
    state.user = user;
  },
};

export default { state, mutations };
