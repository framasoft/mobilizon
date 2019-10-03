import Profile from '@/views/Account/Profile.vue';
import MyAccount from '@/views/Account/MyAccount.vue';
import CreateGroup from '@/views/Group/Create.vue';
import Group from '@/views/Group/Group.vue';
import GroupList from '@/views/Group/GroupList.vue';
import { RouteConfig } from 'vue-router';
import EditIdentity from '@/views/Account/children/EditIdentity.vue';

export enum ActorRouteName {
  GROUP_LIST = 'GroupList',
  GROUP = 'Group',
  CREATE_GROUP = 'CreateGroup',
  PROFILE = 'Profile',
}

export enum MyAccountRouteName {
  CREATE_IDENTITY = 'CreateIdentity',
  UPDATE_IDENTITY = 'UpdateIdentity',
}

export const actorRoutes: RouteConfig[] = [
  // {
  //   path: '/groups',
  //   name: ActorRouteName.GROUP_LIST,
  //   component: GroupList,
  //   meta: { requiredAuth: false },
  // },
  // {
  //   path: '/groups/create',
  //   name: ActorRouteName.CREATE_GROUP,
  //   component: CreateGroup,
  //   meta: { requiredAuth: true },
  // },
  // {
  //   path: '/~:preferredUsername',
  //   name: ActorRouteName.GROUP,
  //   component: Group,
  //   props: true,
  //   meta: { requiredAuth: false },
  // },
  // {
  //   path: '/@:name',
  //   name: ActorRouteName.PROFILE,
  //   component: Profile,
  //   props: true,
  //   meta: { requiredAuth: false },
  // },
  {
    path: '/my-account/identity',
    component: MyAccount,
    props: true,
    meta: { requiredAuth: true },
    children: [
      {
        path: 'create',
        name: MyAccountRouteName.CREATE_IDENTITY,
        component: EditIdentity,
        props: { isUpdate: false },
      },
      {
        path: 'update/:identityName?',
        name: MyAccountRouteName.UPDATE_IDENTITY,
        component: EditIdentity,
        props: { isUpdate: true },
      },
    ],
  },
];
