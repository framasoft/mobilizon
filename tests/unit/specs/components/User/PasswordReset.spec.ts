const useRouterMock = vi.fn(() => ({
  push: function () {
    // do nothing
  },
}));

import { config, mount } from "@vue/test-utils";
import PasswordReset from "@/views/User/PasswordReset.vue";
import { createMockClient, RequestHandler } from "mock-apollo-client";
import { RESET_PASSWORD } from "@/graphql/auth";
import { resetPasswordResponseMock } from "../../mocks/auth";
import RouteName from "@/router/name";
import flushPromises from "flush-promises";
import { describe, expect, it, vi } from "vitest";
import { DefaultApolloClient } from "@vue/apollo-composable";
import Oruga from "@oruga-ui/oruga-next";

config.global.plugins.push(Oruga);

vi.mock("vue-router/dist/vue-router.mjs", () => ({
  useRouter: useRouterMock,
}));

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
  it("renders correctly", () => {
    const wrapper = generateWrapper();
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
    const push = vi.fn(); // needs to write this code before render()
    useRouterMock.mockImplementationOnce(() => ({
      push,
    }));
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
    expect(push).toHaveBeenCalledWith({ name: RouteName.HOME });
  });
});
