import { mount } from "@vue/test-utils";
import PostListItem from "@/components/Post/PostListItem.vue";
import { beforeEach, describe, it, expect } from "vitest";
import { enUS } from "date-fns/locale";
import { routes } from "@/router";
import { createRouter, createWebHistory, Router } from "vue-router";

let router: Router;

beforeEach(async () => {
  router = createRouter({
    history: createWebHistory(),
    routes: routes,
  });

  // await router.isReady();
});

const postData = {
  id: "1",
  slug: "my-blog-post-some-uuid",
  title: "My Blog Post",
  body: "My content",
  insertedAt: "2020-12-02T09:01:20.873Z",
  tags: [],
  language: "en",
};

const generateWrapper = (
  customPostData: Record<string, unknown> = {},
  customProps: Record<string, unknown> = {}
) => {
  return mount(PostListItem, {
    props: {
      post: { ...postData, ...customPostData },
      ...customProps,
    },
    global: {
      provide: {
        dateFnsLocale: enUS,
      },
      plugins: [router],
    },
  });
};

describe("PostListItem", () => {
  it("renders post list item with basic informations", () => {
    const wrapper = generateWrapper();

    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find("a.block.bg-white").attributes("href")).toBe(
      `/p/${postData.slug}`
    );

    expect(wrapper.find("h3").text()).toBe(postData.title);

    expect(wrapper.find("p.flex.gap-2").text()).toBe("Dec 2, 2020");

    expect(wrapper.find("p.flex.gap-1").exists()).toBeFalsy();
  });

  it("renders post list item with tags", () => {
    const wrapper = generateWrapper({
      tags: [{ slug: "a-tag", title: "A tag" }],
    });

    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find("div.flex.flex-wrap.gap-y-0.gap-x-2").text()).toContain(
      "A tag"
    );

    expect(wrapper.find("p.flex.gap-1").exists()).toBeFalsy();
  });

  it("renders post list item with publisher name", () => {
    const wrapper = generateWrapper(
      { author: { name: "An author" } },
      { isCurrentActorMember: true }
    );

    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find("p.flex.gap-1").exists()).toBeTruthy();
    expect(wrapper.find("p.flex.gap-1").text()).toContain("An author");
  });
});
