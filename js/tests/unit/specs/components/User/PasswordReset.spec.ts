import { config, createLocalVue, mount } from "@vue/test-utils";
import PasswordReset from "@/views/User/PasswordReset.vue";
import Buefy from "buefy";
import { createMockClient, RequestHandler } from "mock-apollo-client";
import { RESET_PASSWORD } from "@/graphql/auth";
import VueApollo from "@vue/apollo-option";
import { resetPasswordResponseMock } from "../../mocks/auth";
import RouteName from "@/router/name";
import flushPromises from "flush-promises";

const localVue = createLocalVue();
localVue.use(Buefy);
config.mocks.$t = (key: string): string => key;
const $router = { push: jest.fn() };

let requestHandlers: Record<string, RequestHandler>;

const generateWrapper = (
  customRequestHandlers: Record<string, RequestHandler> = {},
  customMocks = {}
) => {
  const mockClient = createMockClient();

  requestHandlers = {
    resetPasswordMutationHandler: jest
      .fn()
      .mockResolvedValue(resetPasswordResponseMock),
    ...customRequestHandlers,
  };

  mockClient.setRequestHandler(
    RESET_PASSWORD,
    requestHandlers.resetPasswordMutationHandler
  );

  const apolloProvider = new VueApollo({
    defaultClient: mockClient,
  });

  return mount(PasswordReset, {
    localVue,
    mocks: {
      $route: { query: {} },
      $router,
      ...customMocks,
    },
    apolloProvider,
    propsData: {
      token: "some-token",
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
      resetPasswordMutationHandler: jest.fn().mockResolvedValue({
        errors: [{ message: "The token you provided is invalid." }],
      }),
    });

    wrapper.findAll('input[type="password"').setValue("my password");
    wrapper.find("form").trigger("submit");

    await wrapper.vm.$nextTick();

    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledTimes(1);
    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledWith({
      password: "my password",
      token: "some-token",
    });

    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();

    expect(wrapper.find("article.message.is-danger").text()).toContain(
      "The token you provided is invalid"
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("redirects to homepage if token is valid", async () => {
    const wrapper = generateWrapper();

    wrapper.findAll('input[type="password"').setValue("my password");
    wrapper.find("form").trigger("submit");

    await wrapper.vm.$nextTick();

    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledTimes(1);
    expect(requestHandlers.resetPasswordMutationHandler).toBeCalledWith({
      password: "my password",
      token: "some-token",
    });
    expect(jest.isMockFunction(wrapper.vm.$router.push)).toBe(true);
    await flushPromises();
    expect($router.push).toHaveBeenCalledWith({ name: RouteName.HOME });
  });
});
