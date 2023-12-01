import { i18n } from "@/utils/i18n";
import { RouteLocationNormalized, RouteRecordRaw } from "vue-router";

const t = i18n.global.t;

const participations = () => import("@/views/Event/ParticipantsView.vue");
const editEvent = () => import("@/views/Event/EditView.vue");
const event = () => import("@/views/Event/EventView.vue");
const myEvents = () => import("@/views/Event/MyEventsView.vue");

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
  EVENT_PARTICIPATE_CANCEL = "EVENT_PARTICIPATE_CANCEL",
  TAG = "Tag",
}

export const eventRoutes: RouteRecordRaw[] = [
  {
    path: "/events/create",
    name: EventRouteName.CREATE_EVENT,
    component: editEvent,
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => t("Create event") as string },
    },
  },
  {
    path: "/events/me",
    name: EventRouteName.MY_EVENTS,
    component: myEvents,
    props: true,
    meta: {
      requiredAuth: true,
      announcer: { message: (): string => t("My events") as string },
    },
  },
  {
    path: "/events/edit/:eventId",
    name: EventRouteName.EDIT_EVENT,
    component: editEvent,
    meta: { requiredAuth: true, announcer: { skip: true } },
    props: (route: RouteLocationNormalized): Record<string, unknown> => {
      return { ...route.params, ...{ isUpdate: true } };
    },
  },
  {
    path: "/events/duplicate/:eventId",
    name: EventRouteName.DUPLICATE_EVENT,
    component: editEvent,
    meta: { requiredAuth: true, announce: { skip: true } },
    props: (route: RouteLocationNormalized): Record<string, unknown> => ({
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
    component: () =>
      import("../components/Participation/UnloggedParticipation.vue"),
    props: true,
    meta: {
      announcer: {
        message: (): string => t("Unlogged participation") as string,
      },
    },
  },
  {
    path: "/events/:uuid/participate/with-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITH_ACCOUNT,
    component: () =>
      import("../components/Participation/ParticipationWithAccount.vue"),
    meta: {
      announcer: {
        message: (): string => t("Participation with account") as string,
      },
    },
    props: true,
  },
  {
    path: "/events/:uuid/participate/without-account",
    name: EventRouteName.EVENT_PARTICIPATE_WITHOUT_ACCOUNT,
    component: () =>
      import("../components/Participation/ParticipationWithoutAccount.vue"),
    meta: {
      announcer: {
        message: (): string => t("Participation without account") as string,
      },
    },
    props: true,
  },
  {
    path: "/participation/email/confirm/:token",
    name: EventRouteName.EVENT_PARTICIPATE_CONFIRM,
    component: () =>
      import("../components/Participation/ConfirmParticipation.vue"),
    meta: {
      announcer: {
        message: (): string => t("Confirm participation") as string,
      },
    },
    props: true,
  },
  {
    path: "/participation/email/cancel/:uuid/:token",
    name: EventRouteName.EVENT_PARTICIPATE_CANCEL,
    component: () =>
      import("../components/Participation/CancelParticipation.vue"),
    meta: {
      announcer: {
        message: (): string => t("Cancel participation") as string,
      },
    },
    props: true,
  },
  {
    path: "/tag/:tag",
    name: EventRouteName.TAG,
    component: () => import("@/views/SearchView.vue"),
    props: true,
    meta: {
      requiredAuth: false,
      announcer: { message: (): string => t("Tag search") as string },
    },
  },
];
