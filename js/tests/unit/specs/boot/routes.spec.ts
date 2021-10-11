import { config, createLocalVue, mount } from "@vue/test-utils";
import { routes } from "@/router";
import App from "@/App.vue";
import VueRouter from "vue-router";
import Buefy from "buefy";
import flushPromises from "flush-promises";
import VueAnnouncer from "@vue-a11y/announcer";
import VueSkipTo from "@vue-a11y/skip-to";

const localVue = createLocalVue();
config.mocks.$t = (key: string): string => key;
localVue.use(VueRouter);
localVue.use(Buefy);
localVue.use(VueAnnouncer);
localVue.use(VueSkipTo);

describe("routing", () => {
  test("Homepage", async () => {
    const router = new VueRouter({ routes, mode: "history" });
    const wrapper = mount(App, {
      localVue,
      router,
      stubs: {
        NavBar: true,
        "mobilizon-footer": true,
      },
    });

    expect(wrapper.html()).toContain('<div id="homepage">');
  });

  test("About", async () => {
    const router = new VueRouter({ routes, mode: "history" });
    const wrapper = mount(App, {
      localVue,
      router,
      stubs: {
        NavBar: true,
        "mobilizon-footer": true,
      },
    });

    router.push("/about");
    await flushPromises();
    expect(wrapper.vm.$route.path).toBe("/about/instance");
    expect(wrapper.html()).toContain(
      '<a href="/about/instance" aria-current="page"'
    );
  });
});
