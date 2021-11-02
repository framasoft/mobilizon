import { RouteConfig, Route } from "vue-router";
import { ImportedComponent } from "vue/types/options";
import { i18n } from "@/utils/i18n";

const participations = (): Promise<ImportedComponent> =>
  import(
    /* webpackChunkName: "participations" */ "@/views/Event/Participants.vue"
  );
const editEvent = (): Promise<ImportedComponent> =>
  import(/* webpackChunkName: "edit-event" */ "@/views/Event/Edit.vue");
const event = (): Promise<ImportedComponent> =>
  import(/* webpackChunkName: "event" */ "@/views/Event/Event.vue");
const myEvents = (): Promise<ImportedComponent> =>
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
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "EventList" */ "@/views/Event/EventList.vue"),
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Event list") as string },
    },
  },
  {
    path: "/events/create",
    name: EventRouteName.CREATE_EVENT,
    component: editEvent,
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => i18n.t("Create event") as string },
    },
  },
  {
    path: "/events/me",
    name: EventRouteName.MY_EVENTS,
    component: myEvents,
    props: true,
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => i18n.t("My events") as string },
    },
  },
  {
    path: "/events/edit/:eventId",
    name: EventRouteName.EDIT_EVENT,
    component: editEvent,
    meta: { requiredAuth: true, announcer: { skip: true } },
    props: (route: Route): Record<string, unknown> => {
      return { ...route.params, ...{ isUpdate: true } };
    },
  },
  {
    path: "/events/duplicate/:eventId",
    name: EventRouteName.DUPLICATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true, announce: { skip: true } },
    props: (route: Route): Record<string, unknown> => ({
      ...route.params,
      ...{ isDuplicate: true },
    }),
  },
  {
    path: "/events/:eventId/participations",
    name: EventRouteName.PARTICIPATIONS,
    component: participations,
    meta: { requiredAuth: true, announcer: { skip: true } },
    props: true,
  },
  {
    path: "/events/:uuid",
    name: EventRouteName.EVENT,
    component: event,
    props: true,
    meta: { requiredAuth: false, announcer: { skip: true } },
  },
  {
    path: "/events/:uuid/participate",
    name: EventRouteName.EVENT_PARTICIPATE_LOGGED_OUT,
    component: (): Promise<ImportedComponent> =>
      import("../components/Participation/UnloggedParticipation.vue"),
    props: true,
    meta: {
      announcer: {
        message: (): string => i18n.t("Unlogged participation") as string,
      },
    },
  },
  {
    path: "/events/:uuid/participate/with-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITH_ACCOUNT,
    component: (): Promise<ImportedComponent> =>
      import("../components/Participation/ParticipationWithAccount.vue"),
    meta: {
      announcer: {
        message: (): string => i18n.t("Participation with account") as string,
      },
    },
    props: true,
  },
  {
    path: "/events/:uuid/participate/without-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT,
    component: (): Promise<ImportedComponent> =>
      import("../components/Participation/ParticipationWithoutAccount.vue"),
    meta: {
      announcer: {
        message: (): string =>
          i18n.t("Participation without account") as string,
      },
    },
    props: true,
  },
  {
    path: "/participation/email/confirm/:token",
    name: EventRouteName.EVENT_PARTICIPATE_CONFIRM,
    component: (): Promise<ImportedComponent> =>
      import("../components/Participation/ConfirmParticipation.vue"),
    meta: {
      announcer: {
        message: (): string => i18n.t("Confirm participation") as string,
      },
    },
    props: true,
  },
  {
    path: "/tag/:tag",
    name: EventRouteName.TAG,
    component: (): Promise<ImportedComponent> =>
      import(/* webpackChunkName: "Search" */ "@/views/Search.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => i18n.t("Tag search") as string },
    },
  },
];
