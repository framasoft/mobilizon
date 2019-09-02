import EventList from '@/views/Event/EventList.vue';
import Location from '@/views/Location.vue';
import { RouteConfig } from 'vue-router';

// tslint:disable:space-in-parens
const editEvent = () => import(/* webpackChunkName: "create-event" */ '@/views/Event/Edit.vue');
const event = () => import(/* webpackChunkName: "event" */ '@/views/Event/Event.vue');
// tslint:enable

export enum EventRouteName {
  EVENT_LIST = 'EventList',
  CREATE_EVENT = 'CreateEvent',
  EDIT_EVENT = 'EditEvent',
  EVENT = 'Event',
  LOCATION = 'Location',
}

export const eventRoutes: RouteConfig[] = [
  {
    path: '/events/list/:location?',
    name: EventRouteName.EVENT_LIST,
    component: EventList,
    meta: { requiredAuth: false },
  },
  {
    path: '/events/create',
    name: EventRouteName.CREATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
  },
  {
    path: '/events/edit/:eventId',
    name: EventRouteName.EDIT_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
    props: { isUpdate: true },
  },
  {
    path: '/location/new',
    name: EventRouteName.LOCATION,
    component: Location,
    meta: { requiredAuth: true },
  },
  {
    path: '/events/:uuid',
    name: EventRouteName.EVENT,
    component: event,
    props: true,
    meta: { requiredAuth: false },
  },
];
