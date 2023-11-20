const useRouterMock = vi.fn(() => ({
  push: function () {
    // do nothing
  },
}));

import { shallowMount, VueWrapper } from "@vue/test-utils";
import NavBar from "@/components/NavBar.vue";
import { createMockClient, MockApolloClient } from "mock-apollo-client";
import buildCurrentUserResolver from "@/apollo/user";
import { InMemoryCache } from "@apollo/client/cache";
import { describe, it, vi, expect, afterEach } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";

vi.mock("vue-router/dist/vue-router.mjs", () => ({
  useRouter: useRouterMock,
}));

describe("App component", () => {
  let wrapper: VueWrapper;
  let mockClient: MockApolloClient | null;

  const createComponent = () => {
    const cache = new InMemoryCache({ addTypename: false });

    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });

    wrapper = shallowMount(NavBar, {
      // stubs: ["router-link", "router-view", "o-dropdown", "o-dropdown-item"],
      global: {
        provide: {
          [DefaultApolloClient]: mockClient,
        },
      },
    });
  };

  afterEach(() => {
    wrapper?.unmount();
    mockClient = null;
  });

  it("renders a Vue component", async () => {
    const push = vi.fn();
    useRouterMock.mockImplementationOnce(() => ({
      push,
    }));
    createComponent();

    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(wrapper.html()).toMatchSnapshot();
    // expect(wrapper.findComponent({ name: "b-navbar" }).exists()).toBeTruthy();
  });
});
