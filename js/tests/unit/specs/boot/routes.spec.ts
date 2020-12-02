import { config, createLocalVue, mount } from "@vue/test-utils";
import { routes } from "@/router";
import App from "@/App.vue";
import VueRouter from "vue-router";
import Home from "@/views/Home.vue";

const localVue = createLocalVue();
config.mocks.$t = (key: string): string => key;
localVue.use(VueRouter);

const router = new VueRouter({ routes });
const wrapper = mount(App, {
  localVue,
  router,
  stubs: ["NavBar", "mobilizon-footer"],
});

describe("routing", () => {
  test("Homepage", async () => {
    router.push("/");
    await wrapper.vm.$nextTick();
    expect(wrapper.findComponent(Home).exists()).toBe(true);
  });
});
