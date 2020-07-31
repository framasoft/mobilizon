import { RouteConfig, Route } from "vue-router";
import EventList from "../views/Event/EventList.vue";
import Location from "../views/Location.vue";
import Search from "../views/Search.vue";

const participations = () =>
  import(/* webpackChunkName: "participations" */ "@/views/Event/Participants.vue");
const editEvent = () => import(/* webpackChunkName: "edit-event" */ "@/views/Event/Edit.vue");
const event = () => import(/* webpackChunkName: "event" */ "@/views/Event/Event.vue");
const myEvents = () => import(/* webpackChunkName: "my-events" */ "@/views/Event/MyEvents.vue");
const explore = () => import(/* webpackChunkName: "explore" */ "@/views/Event/Explore.vue");

export enum EventRouteName {
  EVENT_LIST = "EventList",
  CREATE_EVENT = "CreateEvent",
  MY_EVENTS = "MyEvents",
  EXPLORE = "Explore",
  EDIT_EVENT = "EditEvent",
  DUPLICATE_EVENT = "DuplicateEvent",
  PARTICIPATIONS = "Participations",
  EVENT = "Event",
  EVENT_PARTICIPATE_WITH_ACCOUNT = "EVENT_PARTICIPATE_WITH_ACCOUNT",
  EVENT_PARTICIPATE_WITHOUT_ACCOUNT = "EVENT_PARTICIPATE_WITHOUT_ACCOUNT",
  EVENT_PARTICIPATE_LOGGED_OUT = "EVENT_PARTICIPATE_LOGGED_OUT",
  EVENT_PARTICIPATE_CONFIRM = "EVENT_PARTICIPATE_CONFIRM",
  LOCATION = "Location",
  TAG = "Tag",
}

export const eventRoutes: RouteConfig[] = [
  {
    path: "/events/list/:location?",
    name: EventRouteName.EVENT_LIST,
    component: EventList,
    meta: { requiredAuth: false },
  },
  {
    path: "/events/create",
    name: EventRouteName.CREATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
  },
  {
    path: "/events/explore",
    name: EventRouteName.EXPLORE,
    component: explore,
    meta: { requiredAuth: false },
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
    props: (route: Route) => ({ ...route.params, ...{ isUpdate: true } }),
  },
  {
    path: "/events/duplicate/:eventId",
    name: EventRouteName.DUPLICATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true },
    props: (route: Route) => ({ ...route.params, ...{ isDuplicate: true } }),
  },
  {
    path: "/events/:eventId/participations",
    name: EventRouteName.PARTICIPATIONS,
    component: participations,
    meta: { requiredAuth: true },
    props: true,
  },
  {
    path: "/location/new",
    name: EventRouteName.LOCATION,
    component: Location,
    meta: { requiredAuth: true },
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
    component: () => import("../components/Participation/UnloggedParticipation.vue"),
    props: true,
  },
  {
    path: "/events/:uuid/participate/with-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITH_ACCOUNT,
    component: () => import("../components/Participation/ParticipationWithAccount.vue"),
    props: true,
  },
  {
    path: "/events/:uuid/participate/without-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT,
    component: () => import("../components/Participation/ParticipationWithoutAccount.vue"),
    props: true,
  },
  {
    path: "/participation/email/confirm/:token",
    name: EventRouteName.EVENT_PARTICIPATE_CONFIRM,
    component: () => import("../components/Participation/ConfirmParticipation.vue"),
    props: true,
  },
  {
    path: "/tag/:tag",
    name: EventRouteName.TAG,
    component: Search,
    props: true,
    meta: { requiredAuth: false },
  },
];
