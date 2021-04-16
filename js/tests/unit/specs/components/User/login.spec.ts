import { config, createLocalVue, mount, Wrapper } from "@vue/test-utils";
import Login from "@/views/User/Login.vue";
import Buefy from "buefy";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import VueApollo from "vue-apollo";
import buildCurrentUserResolver from "@/apollo/user";
import { InMemoryCache } from "apollo-cache-inmemory";
import { configMock } from "../../mocks/config";
import { i18n } from "@/utils/i18n";
import { CONFIG } from "@/graphql/config";
import { loginMock, loginResponseMock } from "../../mocks/auth";
import { LOGIN } from "@/graphql/auth";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";
import flushPromises from "flush-promises";
import RouteName from "@/router/name";

const localVue = createLocalVue();
localVue.use(Buefy);
config.mocks.$t = (key: string): string => key;
const $router = { push: jest.fn() };

describe("Render login form", () => {
  let wrapper: Wrapper<Vue>;
  let mockClient: MockApolloClient | null;
  let apolloProvider;
  let requestHandlers: Record<string, RequestHandler>;

  const generateWrapper = (
    handlers: Record<string, unknown> = {},
    customProps: Record<string, unknown> = {},
    baseData: Record<string, unknown> = {},
    customMocks: Record<string, unknown> = {}
  ) => {
    const cache = new InMemoryCache({ addTypename: true });

    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });

    requestHandlers = {
      configQueryHandler: jest.fn().mockResolvedValue(configMock),
      loginMutationHandler: jest.fn().mockResolvedValue(loginResponseMock),
      ...handlers,
    };
    mockClient.setRequestHandler(CONFIG, requestHandlers.configQueryHandler);
    mockClient.setRequestHandler(LOGIN, requestHandlers.loginMutationHandler);

    apolloProvider = new VueApollo({
      defaultClient: mockClient,
    });

    wrapper = mount(Login, {
      localVue,
      i18n,
      apolloProvider,
      propsData: {
        ...customProps,
      },
      mocks: {
        $route: { query: {} },
        $router,
        ...customMocks,
      },
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
    $router.push.mockReset();
  });

  it("requires email and password to be filled", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    expect(wrapper.vm.$apollo.queries.config).toBeTruthy();
    wrapper.find('form input[type="email"]').setValue("");
    wrapper.find('form input[type="password"]').setValue("");
    wrapper.find("form button.button").trigger("click");
    const form = wrapper.find("form");
    expect(form.exists()).toBe(true);
    const formElement = form.element as HTMLFormElement;
    expect(formElement.checkValidity()).toBe(false);
  });

  it("renders and submits the login form", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    expect(wrapper.vm.$apollo.queries.config).toBeTruthy();
    wrapper.find('form input[type="email"]').setValue("some@email.tld");
    wrapper.find('form input[type="password"]').setValue("somepassword");
    wrapper.find("form").trigger("submit");
    await wrapper.vm.$nextTick();
    expect(requestHandlers.loginMutationHandler).toHaveBeenCalledWith({
      ...loginMock,
    });
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    const currentUser = mockClient?.cache.readQuery<{
      currentUser: ICurrentUser;
    }>({
      query: CURRENT_USER_CLIENT,
    })?.currentUser;
    expect(currentUser?.email).toBe("some@email.tld");
    expect(currentUser?.id).toBe("1");
    expect(jest.isMockFunction(wrapper.vm.$router.push)).toBe(true);
    await flushPromises();
    expect($router.push).toHaveBeenCalledWith({ name: RouteName.HOME });
  });

  it("handles a login error", async () => {
    generateWrapper({
      loginMutationHandler: jest.fn().mockResolvedValue({
        errors: [
          {
            message:
              '"Impossible to authenticate, either your email or password are invalid."',
          },
        ],
      }),
    });

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    expect(wrapper.vm.$apollo.queries.config).toBeTruthy();
    wrapper.find('form input[type="email"]').setValue("some@email.tld");
    wrapper.find('form input[type="password"]').setValue("somepassword");
    wrapper.find("form").trigger("submit");
    await wrapper.vm.$nextTick();
    expect(requestHandlers.loginMutationHandler).toHaveBeenCalledWith({
      ...loginMock,
    });
    await flushPromises();
    expect(wrapper.find("article.message.is-danger").text()).toContain(
      "Impossible to authenticate, either your email or password are invalid."
    );
    expect($router.push).not.toHaveBeenCalled();
  });

  it("handles redirection after login", async () => {
    generateWrapper(
      {},
      {},
      {},
      {
        $route: { query: { redirect: "/about/instance" } },
      }
    );

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    wrapper.find('form input[type="email"]').setValue("some@email.tld");
    wrapper.find('form input[type="password"]').setValue("somepassword");
    wrapper.find("form").trigger("submit");
    await flushPromises();
    expect($router.push).toHaveBeenCalledWith("/about/instance");
  });
});
