import { config, mount, VueWrapper } from "@vue/test-utils";
import ParticipationWithoutAccount from "@/components/Participation/ParticipationWithoutAccount.vue";
import { routes } from "@/router";
import {
  CommentModeration,
  EventJoinOptions,
  ParticipantRole,
} from "@/types/enums";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import { ANONYMOUS_ACTOR_ID } from "@/graphql/config";
import { FETCH_EVENT_BASIC, JOIN_EVENT } from "@/graphql/event";
import { IEvent } from "@/types/event.model";
import { anonymousActorIdMock } from "../../mocks/config";
import {
  fetchEventBasicMock,
  joinEventMock,
  joinEventResponseMock,
} from "../../mocks/event";
import { defaultResolvers } from "../../common";
import flushPromises from "flush-promises";
import { vi, describe, expect, it, beforeEach, afterEach } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";
import { Router, createRouter, createWebHistory } from "vue-router";
import Oruga from "@oruga-ui/oruga-next";
import { cache } from "@/apollo/memory";

config.global.plugins.push(Oruga);
let router: Router;

beforeEach(async () => {
  router = createRouter({
    history: createWebHistory(),
    routes: routes,
  });

  // await router.isReady();
});

const eventData = {
  id: "1",
  uuid: "f37910ea-fd5a-4756-9679-00971f3f4106",
  options: {
    commentModeration: CommentModeration.ALLOW_ALL,
  },
  joinOptions: EventJoinOptions.FREE,
  beginsOn: new Date("2089-12-04T09:21:25Z"),
  endsOn: new Date("2089-12-04T11:21:25Z"),
  participantStats: {
    notApproved: 0,
    notConfirmed: 0,
    rejected: 0,
    participant: 0,
    creator: 1,
    moderator: 0,
    administrator: 0,
    going: 1,
  },
};

describe("ParticipationWithoutAccount", () => {
  let wrapper: VueWrapper;
  let mockClient: MockApolloClient | null;
  let requestHandlers: Record<string, RequestHandler>;

  afterEach(() => {
    wrapper?.unmount();
    cache.reset();
    mockClient = null;
  });

  const generateWrapper = (
    handlers: Record<string, unknown> = {},
    customProps: Record<string, unknown> = {}
  ) => {
    mockClient = createMockClient({
      cache,
      resolvers: defaultResolvers,
    });
    requestHandlers = {
      anonymousActorIdQueryHandler: vi
        .fn()
        .mockResolvedValue(anonymousActorIdMock),
      fetchEventQueryHandler: vi.fn().mockResolvedValue(fetchEventBasicMock),
      joinEventMutationHandler: vi
        .fn()
        .mockResolvedValue(joinEventResponseMock),
      ...handlers,
    };
    mockClient.setRequestHandler(
      ANONYMOUS_ACTOR_ID,
      requestHandlers.anonymousActorIdQueryHandler
    );
    mockClient.setRequestHandler(
      FETCH_EVENT_BASIC,
      requestHandlers.fetchEventQueryHandler
    );
    mockClient.setRequestHandler(
      JOIN_EVENT,
      requestHandlers.joinEventMutationHandler
    );

    wrapper = mount(ParticipationWithoutAccount, {
      props: {
        uuid: eventData.uuid,
        ...customProps,
      },
      global: {
        provide: {
          [DefaultApolloClient]: mockClient,
        },
        plugins: [router],
      },
    });
  };

  it("renders the participation without account view with minimal data", async () => {
    generateWrapper();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.anonymousActorIdQueryHandler).toHaveBeenCalled();

    expect(requestHandlers.fetchEventQueryHandler).toHaveBeenCalledWith({
      uuid: eventData.uuid,
    });
    await flushPromises();

    expect(wrapper.find(".container").isVisible()).toBeTruthy();
    expect(wrapper.find(".o-notification--info").text()).toBe(
      "Your email will only be used to confirm that you're a real person and send you eventual updates for this event. It will NOT be transmitted to other instances or to the event organizer."
    );

    wrapper.find('input[type="email"]').setValue("some@email.tld");
    wrapper.find("textarea").setValue("a message long enough");
    wrapper.find("form").trigger("submit");

    await flushPromises();

    expect(requestHandlers.joinEventMutationHandler).toHaveBeenCalledWith({
      ...joinEventMock,
    });

    const cachedData = mockClient?.cache.readQuery<{ event: IEvent }>({
      query: FETCH_EVENT_BASIC,
      variables: {
        uuid: eventData.uuid,
      },
    });
    if (cachedData) {
      const { event } = cachedData;

      expect(event.participantStats.going).toBe(
        eventData.participantStats.going + 1
      );
      expect(event.participantStats.participant).toBe(
        eventData.participantStats.participant + 1
      );
    }
    await flushPromises();
    expect(wrapper.find("form").exists()).toBeFalsy();
    expect(wrapper.find("h1.title").text()).toBe(
      "Request for participation confirmation sent"
    );
    // TextEncoder ~is~ was not in js-dom?
    // expect(wrapper.find(".o-notification--error").text()).toBe(
    //   "Unable to save your participation in this browser."
    // );

    expect(wrapper.find("span.details").text()).toBe(
      "Your participation will be validated once you click the confirmation link into the email."
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders the warning if the event participation is restricted", async () => {
    generateWrapper({
      fetchEventQueryHandler: vi.fn().mockResolvedValue({
        data: {
          event: {
            ...fetchEventBasicMock.data.event,
            joinOptions: EventJoinOptions.RESTRICTED,
          },
        },
      }),
      joinEventMutationHandler: vi.fn().mockResolvedValue({
        data: {
          joinEvent: {
            ...joinEventResponseMock.data.joinEvent,
            role: ParticipantRole.NOT_CONFIRMED,
          },
        },
      }),
    });

    await flushPromises();

    // expect(wrapper.vm.$data.event.joinOptions).toBe(
    //   EventJoinOptions.RESTRICTED
    // );

    expect(wrapper.findAll("section.container form > p")[1].text()).toContain(
      "The event organizer manually approves participations. Since you've chosen to participate without an account, please explain why you want to participate to this event."
    );
    expect(
      wrapper.findAll("section.container form > p")[1].text()
    ).not.toContain(
      "If you want, you may send a message to the event organizer here."
    );

    wrapper.find('input[type="email"]').setValue("some@email.tld");
    wrapper.find("textarea").setValue("a message long enough");
    wrapper.find("form").trigger("submit");

    await flushPromises();

    expect(requestHandlers.joinEventMutationHandler).toHaveBeenCalledWith({
      ...joinEventMock,
    });

    const cachedData = mockClient?.cache.readQuery<{ event: IEvent }>({
      query: FETCH_EVENT_BASIC,
      variables: {
        uuid: eventData.uuid,
      },
    });
    if (cachedData) {
      const { event } = cachedData;

      expect(event.participantStats.notConfirmed).toBe(
        eventData.participantStats.notConfirmed + 1
      );
    }
    await flushPromises();
    expect(wrapper.find("form").exists()).toBeFalsy();
    expect(wrapper.find("h1.title").text()).toBe(
      "Request for participation confirmation sent"
    );
    expect(wrapper.find("span.details").text()).toBe(
      "Your participation will be validated once you click the confirmation link into the email, and after the organizer manually validates your participation."
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("handles being already a participant", async () => {
    generateWrapper({
      joinEventMutationHandler: vi
        .fn()
        .mockRejectedValue(
          new Error("You are already a participant of this event")
        ),
    });
    await flushPromises();

    wrapper.find('input[type="email"]').setValue("some@email.tld");
    wrapper.find("textarea").setValue("a message long enough");
    wrapper.find("form").trigger("submit");

    await flushPromises();

    expect(requestHandlers.joinEventMutationHandler).toHaveBeenCalledWith({
      ...joinEventMock,
    });
    await flushPromises();
    expect(wrapper.find("form").exists()).toBeTruthy();
    expect(wrapper.find(".o-notification--danger").text()).toContain(
      "You are already a participant of this event"
    );
    expect(wrapper.html()).toMatchSnapshot();
  });
});
