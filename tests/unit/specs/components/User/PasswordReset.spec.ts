import { config, mount } from "@vue/test-utils";
import PasswordReset from "@/views/User/PasswordReset.vue";
import { createMockClient, RequestHandler } from "mock-apollo-client";
import { RESET_PASSWORD } from "@/graphql/auth";
import { resetPasswordResponseMock } from "../../mocks/auth";
import RouteName from "@/router/name";
import flushPromises from "flush-promises";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";
import Oruga from "@oruga-ui/oruga-next";
import {
  VueRouterMock,
  createRouterMock,
  injectRouterMock,
} from "vue-router-mock";

config.global.plugins.push(Oruga);
config.plugins.VueWrapper.install(VueRouterMock);

let requestHandlers: Record<string, RequestHandler>;

const generateWrapper = (
  customRequestHandlers: Record<string, RequestHandler> = {},
  customMocks = {}
) => {
  const mockClient = createMockClient();

  requestHandlers = {
    resetPasswordMutationHandler: vi
      .fn()
      .mockResolvedValue(resetPasswordResponseMock),
    ...customRequestHandlers,
  };

  mockClient.setRequestHandler(
    RESET_PASSWORD,
    requestHandlers.resetPasswordMutationHandler
  );

  return mount(PasswordReset, {
    props: {
      token: "some-token",
    },
    global: {
      stubs: ["router-link", "router-view"],
      mocks: {
        ...customMocks,
      },
      provide: {
        [DefaultApolloClient]: mockClient,
      },
    },
  });
};

describe("Reset page", () => {
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

  it("renders correctly", () => {
    const wrapper = generateWrapper();
    expect(wrapper.router).toBe(router);
    expect(wrapper.findAll('input[type="password"').length).toBe(2);
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("shows error if token is invalid", async () => {
    const wrapper = generateWrapper({
      resetPasswordMutationHandler: vi.fn().mockResolvedValue({
        errors: [{ message: "The token you provided is invalid." }],
      }),
    });

    wrapper
      .findAll('input[type="password"')
      .forEach((inputField) => inputField.setValue("my password"));
    wrapper.find("form").trigger("submit");

    await wrapper.vm.$nextTick();

    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledTimes(1);
    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledWith({
      password: "my password",
      token: "some-token",
    });

    await flushPromises();

    expect(wrapper.find(".o-notification--danger").text()).toContain(
      "The token you provided is invalid"
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("redirects to homepage if token is valid", async () => {
    const wrapper = generateWrapper();

    wrapper
      .findAll('input[type="password"')
      .forEach((inputField) => inputField.setValue("my password"));
    await wrapper.find("form").trigger("submit");

    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledTimes(1);
    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledWith({
      password: "my password",
      token: "some-token",
    });
    await flushPromises();
    expect(wrapper.router.push).toHaveBeenCalledWith({ name: RouteName.HOME });
  });
});
