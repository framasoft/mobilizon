import { config, mount, VueWrapper } from "@vue/test-utils";
import Login from "@/views/User/LoginView.vue";
import {
  createMockClient,
  MockApolloClient,
  RequestHandler,
} from "mock-apollo-client";
import buildCurrentUserResolver from "@/apollo/user";
import { loginMock as loginConfigMock } from "../../mocks/config";
import { LOGIN_CONFIG } from "@/graphql/config";
import { loginMock, loginResponseMock } from "../../mocks/auth";
import { LOGIN } from "@/graphql/auth";
import { CURRENT_USER_CLIENT } from "@/graphql/user";
import { ICurrentUser } from "@/types/current-user.model";
import flushPromises from "flush-promises";
import RouteName from "@/router/name";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";
import Oruga from "@oruga-ui/oruga-next";
import { cache } from "@/apollo/memory";
import {
  VueRouterMock,
  createRouterMock,
  injectRouterMock,
  getRouter,
} from "vue-router-mock";

config.global.plugins.push(Oruga);
config.plugins.VueWrapper.install(VueRouterMock);

describe("Render login form", () => {
  let wrapper: VueWrapper;
  let mockClient: MockApolloClient | null;
  let requestHandlers: Record<string, RequestHandler>;

  const router = createRouterMock({
    spy: {
      create: (fn) => vi.fn(fn),
      reset: (spy) => spy.mockReset(),
    },
  });
  beforeEach(() => {
    // inject it globally to ensure `useRoute()`, `$route`, etc work
    // properly and give you access to test specific functions
    injectRouterMock(router);
  });

  const generateWrapper = (
    handlers: Record<string, unknown> = {},
    customProps: Record<string, unknown> = {},
    customMocks: Record<string, unknown> = {}
  ) => {
    mockClient = createMockClient({
      cache,
      resolvers: buildCurrentUserResolver(cache),
    });

    requestHandlers = {
      configQueryHandler: vi.fn().mockResolvedValue(loginConfigMock),
      loginMutationHandler: vi.fn().mockResolvedValue(loginResponseMock),
      ...handlers,
    };
    mockClient.setRequestHandler(
      LOGIN_CONFIG,
      requestHandlers.configQueryHandler
    );
    mockClient.setRequestHandler(LOGIN, requestHandlers.loginMutationHandler);

    wrapper = mount(Login, {
      props: {
        ...customProps,
      },
      mocks: {
        ...customMocks,
      },
      stubs: ["router-link", "router-view"],
      global: {
        provide: {
          [DefaultApolloClient]: mockClient,
        },
      },
    });
  };

  afterEach(() => {
    wrapper?.unmount();
    cache.reset();
    mockClient = null;
  });

  it("requires email and password to be filled", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await flushPromises();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    wrapper.find('form input[type="email"]').setValue("");
    wrapper.find('form input[type="password"]').setValue("");
    wrapper.find('form button[type="submit"]').trigger("click");
    const form = wrapper.find("form");
    expect(form.exists()).toBe(true);
    const formElement = form.element as HTMLFormElement;
    expect(formElement.checkValidity()).toBe(false);
  });

  it("renders and submits the login form", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await flushPromises();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    wrapper.find('form input[type="email"]').setValue("some@email.tld");
    wrapper.find('form input[type="password"]').setValue("somepassword");
    wrapper.find("form").trigger("submit");
    await wrapper.vm.$nextTick();
    expect(requestHandlers.loginMutationHandler).toHaveBeenCalledWith({
      ...loginMock,
    });
    await flushPromises();
    const currentUser = mockClient?.cache.readQuery<{
      currentUser: ICurrentUser;
    }>({
      query: CURRENT_USER_CLIENT,
    })?.currentUser;

    await flushPromises();
    expect(currentUser?.email).toBe("some@email.tld");
    expect(currentUser?.id).toBe("1");
    await flushPromises();
    expect(wrapper.router.replace).toHaveBeenCalledWith({
      name: RouteName.HOME,
    });
  });

  it("handles a login error", async () => {
    generateWrapper({
      loginMutationHandler: vi.fn().mockResolvedValue({
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
    await flushPromises();

    expect(wrapper.exists()).toBe(true);
    expect(requestHandlers.configQueryHandler).toHaveBeenCalled();
    wrapper.find('form input[type="email"]').setValue("some@email.tld");
    wrapper.find('form input[type="password"]').setValue("somepassword");
    wrapper.find("form").trigger("submit");
    await wrapper.vm.$nextTick();
    expect(requestHandlers.loginMutationHandler).toHaveBeenCalledWith({
      ...loginMock,
    });
    await flushPromises();
    expect(wrapper.find(".o-notification--danger").text()).toContain(
      "Impossible to authenticate, either your email or password are invalid."
    );
    expect(wrapper.router.push).not.toHaveBeenCalled();
  });

  it("handles redirection after login", async () => {
    generateWrapper();
    getRouter().setQuery({ redirect: "/about/instance" });

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
    await flushPromises();

    wrapper.find('form input[type="email"]').setValue("some@email.tld");
    wrapper.find('form input[type="password"]').setValue("somepassword");
    wrapper.find("form").trigger("submit");
    await flushPromises();
    expect(wrapper.router.push).toHaveBeenCalledWith("/about/instance");
  });
});
