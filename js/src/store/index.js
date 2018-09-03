import Vue from 'vue';
import Vuex from 'vuex';
import { LOGIN_USER, LOGOUT_USER, LOAD_USER, CHANGE_ACTOR, LOAD_ACTORS, REMOVE_ACTOR } from './mutation-types';

const state = {
  isLogged: !!localStorage.getItem('token'),
  user: false,
  actors: [],
  defaultActor: null,
  defaultActorUsername: localStorage.getItem('defaultActorUsername') || null,
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

  [LOAD_ACTORS](state, actors) {
    state.actors = actors;
    state.defaultActor = getDefaultActor(actors);
  },

  [CHANGE_ACTOR](state, actor) {
    state.defaultActor = actor;
  },

  [REMOVE_ACTOR](state, actor_deleted) {
    if (state.defaultActor.username === actor_deleted.username) {
      state.defaultActor = state.actors[0];
    }
    state.actors = state.actors.filter(actor => actor.username !== actor_deleted.username)
  }
};
/* eslint-enable */

function getDefaultActor(actors) {
  if (actors.filter(actor => actor === state.defaultActorUsername).length > 0) {
    return actors[0];
  }
  return actors[0];
}

Vue.use(Vuex);
const store = new Vuex.Store({ state, mutations });

store.subscribe((mutation, localState) => {
  if (mutation === CHANGE_ACTOR) {
    localStorage.setItem('defaultActorUsername', localState.defaultActor.username);
  }
});

export default store;
