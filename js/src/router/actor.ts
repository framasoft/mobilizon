import Profile from '@/views/Account/Profile.vue';
import CreateGroup from '@/views/Group/Create.vue';
import Group from '@/views/Group/Group.vue';
import GroupList from '@/views/Group/GroupList.vue';
import Identities from '@/views/Account/Identities.vue';
import { RouteConfig } from 'vue-router';

export enum ActorRouteName {
  IDENTITIES = 'Identities',
  GROUP_LIST = 'GroupList',
  GROUP = 'Group',
  CREATE_GROUP = 'CreateGroup',
  PROFILE = 'Profile',
}

export const actorRoutes: RouteConfig[] = [
  {
    path: '/identities',
    name: ActorRouteName.IDENTITIES,
    component: Identities,
    meta: { requiredAuth: true },
  },
  {
    path: '/groups',
    name: ActorRouteName.GROUP_LIST,
    component: GroupList,
    meta: { requiredAuth: false },
  },
  {
    path: '/groups/create',
    name: ActorRouteName.CREATE_GROUP,
    component: CreateGroup,
    meta: { requiredAuth: true },
  },
  {
    path: '/~:preferredUsername',
    name: ActorRouteName.GROUP,
    component: Group,
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: '/@:name',
    name: ActorRouteName.PROFILE,
    component: Profile,
    props: true,
    meta: { requiredAuth: false },
  },
];
