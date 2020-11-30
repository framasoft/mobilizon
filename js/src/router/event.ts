import { RouteConfig, Route } from "vue-router";
import { EsModuleComponent } from "vue/types/options";

const participations = (): Promise<EsModuleComponent> =>
  import(
    /* webpackChunkName: "participations" */ "@/views/Event/Participants.vue"
  );
const editEvent = (): Promise<EsModuleComponent> =>
  import(/* webpackChunkName: "edit-event" */ "@/views/Event/Edit.vue");
const event = (): Promise<EsModuleComponent> =>
  import(/* webpackChunkName: "event" */ "@/views/Event/Event.vue");
const myEvents = (): Promise<EsModuleComponent> =>
  import(/* webpackChunkName: "my-events" */ "@/views/Event/MyEvents.vue");

export enum EventRouteName {
  EVENT_LIST = "EventList",
  CREATE_EVENT = "CreateEvent",
  MY_EVENTS = "MyEvents",
  EDIT_EVENT = "EditEvent",
  DUPLICATE_EVENT = "DuplicateEvent",
  PARTICIPATIONS = "Participations",
  EVENT = "Event",
  EVENT_PARTICIPATE_WITH_ACCOUNT = "EVENT_PARTICIPATE_WITH_ACCOUNT",
  EVENT_PARTICIPATE_WITHOUT_ACCOUNT = "EVENT_PARTICIPATE_WITHOUT_ACCOUNT",
  EVENT_PARTICIPATE_LOGGED_OUT = "EVENT_PARTICIPATE_LOGGED_OUT",
  EVENT_PARTICIPATE_CONFIRM = "EVENT_PARTICIPATE_CONFIRM",
  TAG = "Tag",
}

export const eventRoutes: RouteConfig[] = [
  {
    path: "/events/list/:location?",
    name: EventRouteName.EVENT_LIST,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "EventList" */ "@/views/Event/EventList.vue"),
    meta: { requiredAuth: false },
  },
  {
    path: "/events/create",
    name: EventRouteName.CREATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
  },
  {
    path: "/events/me",
    name: EventRouteName.MY_EVENTS,
    component: myEvents,
    meta: { requiredAuth: true },
  },
  {
    path: "/events/edit/:eventId",
    name: EventRouteName.EDIT_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
    props: (route: Route): Record<string, unknown> => {
      return { ...route.params, ...{ isUpdate: true } };
    },
  },
  {
    path: "/events/duplicate/:eventId",
    name: EventRouteName.DUPLICATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
    props: (route: Route): Record<string, unknown> => ({
      ...route.params,
      ...{ isDuplicate: true },
    }),
  },
  {
    path: "/events/:eventId/participations",
    name: EventRouteName.PARTICIPATIONS,
    component: participations,
    meta: { requiredAuth: true },
    props: true,
  },
  {
    path: "/events/:uuid",
    name: EventRouteName.EVENT,
    component: event,
    props: true,
    meta: { requiredAuth: false },
  },
  {
    path: "/events/:uuid/participate",
    name: EventRouteName.EVENT_PARTICIPATE_LOGGED_OUT,
    component: (): Promise<EsModuleComponent> =>
      import("../components/Participation/UnloggedParticipation.vue"),
    props: true,
  },
  {
    path: "/events/:uuid/participate/with-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITH_ACCOUNT,
    component: (): Promise<EsModuleComponent> =>
      import("../components/Participation/ParticipationWithAccount.vue"),
    props: true,
  },
  {
    path: "/events/:uuid/participate/without-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT,
    component: (): Promise<EsModuleComponent> =>
      import("../components/Participation/ParticipationWithoutAccount.vue"),
    props: true,
  },
  {
    path: "/participation/email/confirm/:token",
    name: EventRouteName.EVENT_PARTICIPATE_CONFIRM,
    component: (): Promise<EsModuleComponent> =>
      import("../components/Participation/ConfirmParticipation.vue"),
    props: true,
  },
  {
    path: "/tag/:tag",
    name: EventRouteName.TAG,
    component: (): Promise<EsModuleComponent> =>
      import(/* webpackChunkName: "Search" */ "@/views/Search.vue"),
    props: true,
    meta: { requiredAuth: false },
  },
];
