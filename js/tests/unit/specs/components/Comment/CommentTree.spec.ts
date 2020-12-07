import { config, createLocalVue, shallowMount, Wrapper } from "@vue/test-utils";
import CommentTree from "@/components/Comment/CommentTree.vue";
import Buefy from "buefy";
import { InMemoryCache } from "apollo-cache-inmemory";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import buildCurrentUserResolver from "@/apollo/user";
import VueApollo from "vue-apollo";
import { COMMENTS_THREADS, CREATE_COMMENT_FROM_EVENT } from "@/graphql/comment";
import { CommentModeration } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import {
  eventCommentThreadsMock,
  newCommentForEventMock,
  newCommentForEventResponse,
} from "../../mocks/event";

const localVue = createLocalVue();
localVue.use(Buefy);
localVue.use(VueApollo);
config.mocks.$t = (key: string): string => key;

const eventData = {
  id: "1",
  uuid: "e37910ea-fd5a-4756-7634-00971f3f4107",
  options: {
    commentModeration: CommentModeration.ALLOW_ALL,
  },
};
describe("CommentTree", () => {
  let wrapper: Wrapper<Vue>;
  let mockClient: MockApolloClient;
  let apolloProvider;
  let requestHandlers: Record<string, RequestHandler>;

  const generateWrapper = (handlers = {}, baseData = {}) => {
    const cache = new InMemoryCache({ addTypename: false });

    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });

    requestHandlers = {
      eventCommentThreadsQueryHandler: jest
        .fn()
        .mockResolvedValue(eventCommentThreadsMock),
      createCommentForEventMutationHandler: jest
        .fn()
        .mockResolvedValue(newCommentForEventResponse),
      ...handlers,
    };

    mockClient.setRequestHandler(
      COMMENTS_THREADS,
      requestHandlers.eventCommentThreadsQueryHandler
    );
    mockClient.setRequestHandler(
      CREATE_COMMENT_FROM_EVENT,
      requestHandlers.createCommentForEventMutationHandler
    );

    apolloProvider = new VueApollo({
      defaultClient: mockClient,
    });

    wrapper = shallowMount(CommentTree, {
      localVue,
      apolloProvider,
      propsData: {
        event: { ...eventData },
      },
      stubs: ["editor"],
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

  it("renders a comment tree", async () => {
    generateWrapper();

    expect(wrapper.findComponent({ name: "b-notification" }).text()).toBe(
      "The organiser has chosen to close comments."
    );
    expect(wrapper.find(".loading").text()).toBe("Loading comments…");
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders a comment tree", async () => {
    generateWrapper();

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick(); // because of the <transition>

    expect(wrapper.exists()).toBe(true);
    expect(
      requestHandlers.eventCommentThreadsQueryHandler
    ).toHaveBeenCalledWith({ eventUUID: eventData.uuid });
    expect(wrapper.vm.$apollo.queries.comments).toBeTruthy();
    expect(wrapper.find(".loading").exists()).toBe(false);
    expect(wrapper.findAll(".comment-list .root-comment").length).toBe(2);
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders the form if we can comment", async () => {
    generateWrapper(
      {},
      {
        newComment: {
          text: newCommentForEventMock.text,
        },
      }
    );

    wrapper.setData({
      currentActor: {
        id: "67",
      },
    });

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick(); // because of the <transition>

    expect(wrapper.find("form.new-comment").isVisible()).toBe(true);
    expect(wrapper.findAll(".comment-list .root-comment").length).toBe(2);

    wrapper.find("form.new-comment").trigger("submit");

    await wrapper.vm.$nextTick();
    expect(
      requestHandlers.createCommentForEventMutationHandler
    ).toHaveBeenCalledWith({
      ...newCommentForEventMock,
    });

    if (mockClient) {
      const cachedData = mockClient.cache.readQuery<{ event: IEvent }>({
        query: COMMENTS_THREADS,
        variables: {
          eventUUID: eventData.uuid,
        },
      });
      if (cachedData) {
        const { event } = cachedData;

        expect(event.comments).toHaveLength(3);
      }
    }
  });
});
