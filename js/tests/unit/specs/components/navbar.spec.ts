import { shallowMount, createLocalVue, Wrapper, config } from "@vue/test-utils";
import NavBar from "@/components/NavBar.vue";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import VueApollo from "vue-apollo";
import { CONFIG } from "@/graphql/config";
import { USER_SETTINGS } from "@/graphql/user";
import { InMemoryCache } from "apollo-cache-inmemory";
import buildCurrentUserResolver from "@/apollo/user";
import Buefy from "buefy";
import { configMock } from "../mocks/config";

const localVue = createLocalVue();
localVue.use(VueApollo);
localVue.use(Buefy);
config.mocks.$t = (key: string): string => key;

describe("App component", () => {
  let wrapper: Wrapper<Vue>;
  let mockClient: MockApolloClient | null;
  let apolloProvider;
  let requestHandlers: Record<string, RequestHandler>;

  const createComponent = (handlers = {}, baseData = {}) => {
    const cache = new InMemoryCache({ addTypename: true });

    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });

    requestHandlers = {
      configQueryHandler: jest.fn().mockResolvedValue(configMock),
      loggedUserQueryHandler: jest.fn().mockResolvedValue(null),
      ...handlers,
    };

    mockClient.setRequestHandler(CONFIG, requestHandlers.configQueryHandler);

    mockClient.setRequestHandler(
      USER_SETTINGS,
      requestHandlers.loggedUserQueryHandler
    );

    apolloProvider = new VueApollo({
      defaultClient: mockClient,
    });

    wrapper = shallowMount(NavBar, {
      localVue,
      apolloProvider,
      stubs: ["router-link", "router-view"],
      data() {
        return {
          ...baseData,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    mockClient = null;
    apolloProvider = null;
  });

  it("renders a Vue component", async () => {
    createComponent();

    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    expect(wrapper.vm.$apollo.queries.config).toBeTruthy();
    expect(wrapper.html()).toMatchSnapshot();
    expect(wrapper.findComponent({ name: "b-navbar" }).exists()).toBeTruthy();
  });
});
