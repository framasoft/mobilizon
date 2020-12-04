import { config, createLocalVue, mount, Wrapper } from "@vue/test-utils";
import ParticipationSection from "@/components/Participation/ParticipationSection.vue";
import Buefy from "buefy";
import VueRouter from "vue-router";
import { routes } from "@/router";
import { CommentModeration, EventJoinOptions } from "@/types/enums";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import buildCurrentUserResolver from "@/apollo/user";
import { InMemoryCache } from "apollo-cache-inmemory";
import { CONFIG } from "@/graphql/config";
import VueApollo from "vue-apollo";
import { configMock } from "../../mocks/config";

const localVue = createLocalVue();
localVue.use(Buefy);
localVue.use(VueRouter);
const router = new VueRouter({ routes, mode: "history" });
config.mocks.$t = (key: string): string => key;

const eventData = {
  id: "1",
  uuid: "e37910ea-fd5a-4756-7634-00971f3f4107",
  options: {
    commentModeration: CommentModeration.ALLOW_ALL,
  },
  beginsOn: new Date("2089-12-04T09:21:25Z"),
  endsOn: new Date("2089-12-04T11:21:25Z"),
};

describe("ParticipationSection", () => {
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
      ...handlers,
    };
    mockClient.setRequestHandler(CONFIG, requestHandlers.configQueryHandler);

    apolloProvider = new VueApollo({
      defaultClient: mockClient,
    });

    wrapper = mount(ParticipationSection, {
      localVue,
      router,
      apolloProvider,
      propsData: {
        participation: null,
        event: eventData,
        anonymousParticipation: null,
        ...customProps,
      },
      data() {
        return {
          currentActor: {
            id: "76",
          },
          ...baseData,
        };
      },
    });
  };

  it("renders the participation section with minimal data", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    expect(wrapper.vm.$apollo.queries.config).toBeTruthy();

    expect(wrapper.find(".event-participation").exists()).toBeTruthy();

    const participationButton = wrapper.find(
      ".event-participation .participation-button a.button.is-large.is-primary"
    );
    expect(participationButton.attributes("href")).toBe(
      `/events/${eventData.uuid}/participate/with-account`
    );

    expect(participationButton.text()).toBe("Participate");
  });

  it("renders the participation section with existing confimed anonymous participation", async () => {
    generateWrapper({}, { anonymousParticipation: true });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously"
    );

    const cancelAnonymousParticipationButton = wrapper.find(
      ".event-participation > button.button.is-text"
    );
    expect(cancelAnonymousParticipationButton.text()).toBe(
      "Cancel anonymous participation"
    );

    wrapper.find(".event-participation small .is-clickable").trigger("click");
    expect(
      wrapper
        .findComponent({ ref: "anonymous-participation-modal" })
        .isVisible()
    ).toBeTruthy();

    cancelAnonymousParticipationButton.trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted("cancel-anonymous-participation")).toBeTruthy();
  });

  it("renders the participation section with existing confimed anonymous participation but event moderation", async () => {
    generateWrapper(
      {},
      {
        anonymousParticipation: true,
        event: { ...eventData, joinOptions: EventJoinOptions.RESTRICTED },
      }
    );

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously"
    );

    const cancelAnonymousParticipationButton = wrapper.find(
      ".event-participation > button.button.is-text"
    );
    expect(cancelAnonymousParticipationButton.text()).toBe(
      "Cancel anonymous participation"
    );

    wrapper.find(".event-participation small .is-clickable").trigger("click");

    await wrapper.vm.$nextTick();
    const modal = wrapper.findComponent({
      ref: "anonymous-participation-modal",
    });
    expect(modal.isVisible()).toBeTruthy();
    expect(modal.find("article.notification.is-primary").text()).toBe(
      "As the event organizer has chosen to manually validate participation requests, your participation will be really confirmed only once you receive an email stating it's being accepted."
    );

    cancelAnonymousParticipationButton.trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted("cancel-anonymous-participation")).toBeTruthy();
  });

  it("renders the participation section with existing unconfirmed anonymous participation", async () => {
    generateWrapper({}, { anonymousParticipation: false });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously but didn't confirm participation"
    );
  });

  it("renders the participation section but the event is already passed", async () => {
    generateWrapper(
      {},
      {
        event: {
          ...eventData,
          beginsOn: "2020-12-02T10:52:56Z",
          endsOn: "2020-12-03T10:52:56Z",
        },
      }
    );

    expect(wrapper.find(".event-participation").exists()).toBeFalsy();
    expect(wrapper.find("button.button.is-primary").text()).toBe(
      "Event already passed"
    );
  });
});
