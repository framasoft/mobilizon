import { config, createLocalVue, mount } from "@vue/test-utils";
import PostListItem from "@/components/Post/PostListItem.vue";
import Buefy from "buefy";
import VueRouter from "vue-router";
import { routes } from "@/router";
import { enUS } from "date-fns/locale";
import { formatDateTimeString } from "@/filters/datetime";
import { i18n } from "@/utils/i18n";

const localVue = createLocalVue();
localVue.use(Buefy);
localVue.use(VueRouter);
localVue.use((vue) => {
  vue.prototype.$dateFnsLocale = enUS;
});
const router = new VueRouter({ routes, mode: "history" });
config.mocks.$t = (key: string): string => key;

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
    localVue,
    router,
    i18n,
    propsData: {
      post: { ...postData, ...customPostData },
      ...customProps,
    },
    filters: {
      formatDateTimeString,
    },
  });
};

describe("PostListItem", () => {
  it("renders post list item with basic informations", () => {
    const wrapper = generateWrapper();

    expect(wrapper.html()).toMatchSnapshot();

    expect(
      wrapper.find("a.post-minimalist-card-wrapper").attributes("href")
    ).toBe(`/p/${postData.slug}`);

    expect(wrapper.find(".post-minimalist-title").text()).toBe(postData.title);

    expect(wrapper.find(".post-publication-date").text()).toBe("Dec 2, 2020");

    expect(wrapper.find(".post-publisher").exists()).toBeFalsy();
  });

  it("renders post list item with tags", () => {
    const wrapper = generateWrapper({
      tags: [{ slug: "a-tag", title: "A tag" }],
    });

    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find(".tags").text()).toContain("A tag");

    expect(wrapper.find(".post-publisher").exists()).toBeFalsy();
  });

  it("renders post list item with publisher name", () => {
    const wrapper = generateWrapper(
      { author: { name: "An author" } },
      { isCurrentActorMember: true }
    );

    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find(".post-publisher").exists()).toBeTruthy();
    expect(wrapper.find(".post-publisher").text()).toContain("An author");
  });
});
