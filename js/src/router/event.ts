import EventList from '@/views/Event/EventList.vue';
import Location from '@/views/Location.vue';
import CreateEvent from '@/views/Event/Create.vue';
import Event from '@/views/Event/Event.vue';
import { RouteConfig } from 'vue-router';

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
    component: CreateEvent,
    meta: { requiredAuth: true },
  },
  {
    path: '/events/:id/edit',
    name: EventRouteName.EDIT_EVENT,
    component: CreateEvent,
    props: true,
    meta: { requiredAuth: true },
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
    component: Event,
    props: true,
    meta: { requiredAuth: false },
  },
];
