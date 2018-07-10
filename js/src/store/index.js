import Vue from 'vue';
import Vuex from 'vuex';
import { LOGIN_USER, LOGOUT_USER, LOAD_USER, CHANGE_ACTOR } from './mutation-types';

const state = {
  isLogged: !!localStorage.getItem('token'),
  user: false,
  actor: false,
  defaultActor: localStorage.getItem('defaultActor') || null,
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

  [CHANGE_ACTOR](state, actor) {
    state.actor = actor;
    state.defaultActor = actor.username;
  }
};
/* eslint-enable */

Vue.use(Vuex);
const store = new Vuex.Store({ state, mutations });

store.subscribe((mutation, localState) => {
  if (mutation === CHANGE_ACTOR) {
    localStorage.setItem('defaultActor', localState.actor.username);
  }
});

export default store;
