import { config, createLocalVue, mount, Wrapper } from "@vue/test-utils";
import ParticipationWithoutAccount from "@/components/Participation/ParticipationWithoutAccount.vue";
import Buefy from "buefy";
import VueRouter from "vue-router";
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
import buildCurrentUserResolver from "@/apollo/user";
import { InMemoryCache } from "apollo-cache-inmemory";
import { CONFIG } from "@/graphql/config";
import VueApollo from "vue-apollo";
import { FETCH_EVENT_BASIC, JOIN_EVENT } from "@/graphql/event";
import { IEvent } from "@/types/event.model";
import { i18n } from "@/utils/i18n";
import { configMock } from "../../mocks/config";
import {
  fetchEventBasicMock,
  joinEventMock,
  joinEventResponseMock,
} from "../../mocks/event";

const localVue = createLocalVue();
localVue.use(Buefy);
localVue.use(VueRouter);
const router = new VueRouter({ routes, mode: "history" });
config.mocks.$t = (key: string): string => key;

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
  let wrapper: Wrapper<Vue>;
  let mockClient: MockApolloClient;
  let apolloProvider;
  let requestHandlers: Record<string, RequestHandler>;

  const generateWrapper = (
    handlers: Record<string, unknown> = {},
    customProps: Record<string, unknown> = {},
    baseData: Record<string, unknown> = {}
  ) => {
    const cache = new InMemoryCache({ addTypename: false });

    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });
    requestHandlers = {
      configQueryHandler: jest.fn().mockResolvedValue(configMock),
      fetchEventQueryHandler: jest.fn().mockResolvedValue(fetchEventBasicMock),
      joinEventMutationHandler: jest
        .fn()
        .mockResolvedValue(joinEventResponseMock),
      ...handlers,
    };
    mockClient.setRequestHandler(CONFIG, requestHandlers.configQueryHandler);
    mockClient.setRequestHandler(
      FETCH_EVENT_BASIC,
      requestHandlers.fetchEventQueryHandler
    );
    mockClient.setRequestHandler(
      JOIN_EVENT,
      requestHandlers.joinEventMutationHandler
    );

    apolloProvider = new VueApollo({
      defaultClient: mockClient,
    });

    wrapper = mount(ParticipationWithoutAccount, {
      localVue,
      router,
      i18n,
      apolloProvider,
      propsData: {
        uuid: eventData.uuid,
        ...customProps,
      },
      data() {
        return {
          ...baseData,
        };
      },
    });
  };

  it("renders the participation without account view with minimal data", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    expect(wrapper.vm.$apollo.queries.config).toBeTruthy();

    expect(requestHandlers.fetchEventQueryHandler).toHaveBeenCalledWith({
      uuid: eventData.uuid,
    });
    expect(wrapper.vm.$apollo.queries.event).toBeTruthy();

    expect(wrapper.find(".hero-body .container").isVisible()).toBeTruthy();
    expect(wrapper.find("article.message.is-info").text()).toBe(
      "Your email will only be used to confirm that you're a real person and send you eventual updates for this event. It will NOT be transmitted to other instances or to the event organizer."
    );

    wrapper.find('input[type="email"]').setValue("some@email.tld");
    wrapper.find("textarea").setValue("a message long enough");
    wrapper.find("form").trigger("submit");

    await wrapper.vm.$nextTick();

    expect(requestHandlers.joinEventMutationHandler).toHaveBeenCalledWith({
      ...joinEventMock,
    });

    const cachedData = mockClient.cache.readQuery<{ event: IEvent }>({
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
    // lots of things to await
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    expect(wrapper.find("form").exists()).toBeFalsy();
    expect(wrapper.find("h1.title").text()).toBe(
      "Request for participation confirmation sent"
    );
    // TextEncoder is not in js-dom
    expect(
      wrapper.find("article.message.is-warning .media-content").text()
    ).toBe("Unable to save your participation in this browser.");

    expect(wrapper.find("span.details").text()).toBe(
      "Your participation will be validated once you click the confirmation link into the email."
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders the warning if the event participation is restricted", async () => {
    generateWrapper({
      fetchEventQueryHandler: jest.fn().mockResolvedValue({
        data: {
          event: {
            ...fetchEventBasicMock.data.event,
            joinOptions: EventJoinOptions.RESTRICTED,
          },
        },
      }),
      joinEventMutationHandler: jest.fn().mockResolvedValue({
        data: {
          joinEvent: {
            ...joinEventResponseMock.data.joinEvent,
            role: ParticipantRole.NOT_CONFIRMED,
          },
        },
      }),
    });

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.$data.event.joinOptions).toBe(
      EventJoinOptions.RESTRICTED
    );

    expect(wrapper.find(".hero-body .container").text()).toContain(
      "The event organizer manually approves participations. Since you've chosen to participate without an account, please explain why you want to participate to this event."
    );
    expect(wrapper.find(".hero-body .container").text()).not.toContain(
      "If you want, you may send a message to the event organizer here."
    );

    wrapper.find('input[type="email"]').setValue("some@email.tld");
    wrapper.find("textarea").setValue("a message long enough");
    wrapper.find("form").trigger("submit");

    await wrapper.vm.$nextTick();

    expect(requestHandlers.joinEventMutationHandler).toHaveBeenCalledWith({
      ...joinEventMock,
    });

    const cachedData = mockClient.cache.readQuery<{ event: IEvent }>({
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
    // lots of things to await
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
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
      joinEventMutationHandler: jest
        .fn()
        .mockRejectedValue(
          new Error("You are already a participant of this event")
        ),
    });
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    wrapper.find('input[type="email"]').setValue("some@email.tld");
    wrapper.find("textarea").setValue("a message long enough");
    wrapper.find("form").trigger("submit");

    await wrapper.vm.$nextTick();

    expect(requestHandlers.joinEventMutationHandler).toHaveBeenCalledWith({
      ...joinEventMock,
    });
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    expect(wrapper.find("form").exists()).toBeTruthy();
    expect(
      wrapper.find("article.message.is-danger .media-content").text()
    ).toContain("You are already a participant of this event");
    expect(wrapper.html()).toMatchSnapshot();
  });
});
