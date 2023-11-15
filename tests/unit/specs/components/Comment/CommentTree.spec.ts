import { config, shallowMount, VueWrapper } from "@vue/test-utils";
import CommentTree from "@/components/Comment/CommentTree.vue";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import {
  COMMENTS_THREADS_WITH_REPLIES,
  CREATE_COMMENT_FROM_EVENT,
} from "@/graphql/comment";
import { CommentModeration } from "@/types/enums";
import { IEvent } from "@/types/event.model";
import {
  eventCommentThreadsMock,
  eventNoCommentThreadsMock,
  newCommentForEventMock,
  newCommentForEventResponse,
} from "../../mocks/event";
import flushPromises from "flush-promises";
import { defaultResolvers } from "../../common";
import { afterEach, describe, vi, it, expect, beforeEach } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";
import Oruga from "@oruga-ui/oruga-next";
import { notifierPlugin } from "@/plugins/notifier";
import { InMemoryCache } from "@apollo/client/cache";
import { createRouter, createWebHistory, Router } from "vue-router";
import { routes } from "@/router";
import { dialogPlugin } from "@/plugins/dialog";

config.global.plugins.push(Oruga);
config.global.plugins.push(notifierPlugin);
config.global.plugins.push(dialogPlugin);

let router: Router;

const eventData = {
  id: "1",
  uuid: "e37910ea-fd5a-4756-7634-00971f3f4107",
  options: {
    commentModeration: CommentModeration.ALLOW_ALL,
  },
};
describe("CommentTree", () => {
  let wrapper: VueWrapper;
  let mockClient: MockApolloClient | null;
  let requestHandlers: Record<string, RequestHandler>;

  const generateWrapper = (handlers = {}, extraProps = {}) => {
    const cache = new InMemoryCache({ addTypename: true });

    mockClient = createMockClient({
      cache,
      resolvers: defaultResolvers,
    });

    requestHandlers = {
      eventCommentThreadsQueryHandler: vi
        .fn()
        .mockResolvedValue(eventCommentThreadsMock),
      createCommentForEventMutationHandler: vi
        .fn()
        .mockResolvedValue(newCommentForEventResponse),
      ...handlers,
    };

    mockClient.setRequestHandler(
      COMMENTS_THREADS_WITH_REPLIES,
      requestHandlers.eventCommentThreadsQueryHandler
    );
    mockClient.setRequestHandler(
      CREATE_COMMENT_FROM_EVENT,
      requestHandlers.createCommentForEventMutationHandler
    );
    wrapper = shallowMount(CommentTree, {
      props: {
        event: { ...eventData },
        ...extraProps,
      },
      global: {
        provide: {
          [DefaultApolloClient]: mockClient,
        },
        plugins: [router],
      },
    });
  };

  beforeEach(async () => {
    router = createRouter({
      history: createWebHistory(),
      routes: routes,
    });

    // await router.isReady();
  });

  afterEach(() => {
    mockClient = null;
    requestHandlers = {};
    wrapper.unmount();
  });

  it("renders a loading comment tree", async () => {
    generateWrapper();

    expect(wrapper.find("p.text-center").text()).toBe("Loading comments…");

    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders a comment tree with comments", async () => {
    generateWrapper();

    expect(wrapper.exists()).toBe(true);
    expect(
      requestHandlers.eventCommentThreadsQueryHandler
    ).toHaveBeenCalledWith({ eventUUID: eventData.uuid });
    await flushPromises();
    expect(wrapper.find("p.text-center").exists()).toBe(false);

    expect(wrapper.findAllComponents("event-comment-stub").length).toBe(2);
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders the form if we can comment", async () => {
    generateWrapper(
      {},
      {
        newComment: {
          text: newCommentForEventMock.text,
          isAnnouncement: false,
          insertedAt: "2021-12-03T13:02:00Z",
          updatedAt: "2021-12-03T13:02:00Z",
          publishedAt: "2021-12-03T13:02:00Z",
        },
      }
    );

    await flushPromises();

    expect(wrapper.find("form").isVisible()).toBe(true);
    expect(wrapper.findAllComponents("event-comment-stub").length).toBe(2);
    wrapper.getComponent({ ref: "commenteditor" });

    wrapper.find("form").trigger("submit");

    await flushPromises();
    expect(
      requestHandlers.createCommentForEventMutationHandler
    ).toHaveBeenCalledWith({
      ...newCommentForEventMock,
    });

    if (mockClient) {
      const cachedData = mockClient.cache.readQuery<{ event: IEvent }>({
        query: COMMENTS_THREADS_WITH_REPLIES,
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

  it("renders an empty comment tree", async () => {
    generateWrapper({
      eventCommentThreadsQueryHandler: vi
        .fn()
        .mockResolvedValue(eventNoCommentThreadsMock),
    });

    await flushPromises();
    expect(
      requestHandlers.eventCommentThreadsQueryHandler
    ).toHaveBeenCalledWith({ eventUUID: eventData.uuid });

    expect(wrapper.findComponent({ name: "EmptyContent" }).exists());
    expect(wrapper.html()).toMatchSnapshot();
  });
});
