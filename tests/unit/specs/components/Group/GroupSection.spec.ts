import { config, mount } from "@vue/test-utils";
import GroupSection from "@/components/Group/GroupSection.vue";
import RouteName from "@/router/name";
import { routes } from "@/router";
import { describe, it, expect, beforeEach } from "vitest";
import { createRouter, createWebHistory, Router } from "vue-router";
import Oruga from "@oruga-ui/oruga-next";

config.global.plugins.push(Oruga);

let router: Router;

beforeEach(async () => {
  router = createRouter({
    history: createWebHistory(),
    routes: routes,
  });

  // await router.isReady();
});

const groupPreferredUsername = "my_group";
const groupDomain = "remotedomain.net";
const groupUsername = `${groupPreferredUsername}@${groupDomain}`;

const defaultSlotText = "A list of elements";
const createSlotButtonText = "+ Create a post";

type Props = {
  title?: string;
  icon?: string;
  route?: { name: string; params: { preferredUsername: string } };
};

const baseProps: Props = {
  title: "My group section",
  icon: "bullhorn",
  route: {
    name: RouteName.POSTS,
    params: {
      preferredUsername: groupUsername,
    },
  },
};

const generateWrapper = (customProps: Props = {}) => {
  return mount(GroupSection, {
    props: { ...baseProps, ...customProps },
    slots: {
      default: `<div>${defaultSlotText}</div>`,
      create: `<router-link :to="{ 
        name: 'POST_CREATE',
        params: {
          preferredUsername: '${groupUsername}'
        }
      }"
      class="btn-primary">${createSlotButtonText}</router-link>`,
    },
    global: {
      plugins: [router],
    },
  });
};

describe("GroupSection", () => {
  it("renders group section with basic informations", () => {
    const wrapper = generateWrapper();

    expect(wrapper.find("i.mdi").classes(`mdi-${baseProps.icon}`)).toBe(true);

    expect(wrapper.find("h2").text()).toBe(baseProps.title);

    expect(wrapper.find("a").attributes("href")).toBe(`/@${groupUsername}/p`);

    expect(wrapper.find("section > div.flex-1").text()).toBe(defaultSlotText);
    expect(wrapper.find(".flex.justify-end.p-2 a").text()).toBe(
      createSlotButtonText
    );
    expect(wrapper.find(".flex.justify-end.p-2 a").attributes("href")).toBe(
      `/@${groupUsername}/p/new`
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders public group section", () => {
    const wrapper = generateWrapper();

    expect(wrapper.html()).toMatchSnapshot();
  });
});
