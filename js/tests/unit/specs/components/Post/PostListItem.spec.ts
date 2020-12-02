import { config, createLocalVue, mount } from "@vue/test-utils";
import PostListItem from "@/components/Post/PostListItem.vue";
import Buefy from "buefy";
import VueRouter from "vue-router";
import { routes } from "@/router";

const localVue = createLocalVue();
localVue.use(Buefy);
localVue.use(VueRouter);
const router = new VueRouter({ routes, mode: "history" });
config.mocks.$t = (key: string): string => key;

const postData = {
  id: "1",
  slug: "my-blog-post-some-uuid",
  title: "My Blog Post",
  body: "My content",
  insertedAt: "2020-12-02T09:01:20.873Z",
};

const generateWrapper = (customPostData: Record<string, unknown> = {}) => {
  return mount(PostListItem, {
    localVue,
    router,
    propsData: {
      post: { ...postData, ...customPostData },
    },
  });
};

describe("PostListItem", () => {
  it("renders post list item with basic informations", () => {
    const wrapper = generateWrapper();

    // can't use the snapshot feature because of `ago`

    expect(
      wrapper.find("a.post-minimalist-card-wrapper").attributes("href")
    ).toBe(`/p/${postData.slug}`);

    expect(wrapper.find(".post-minimalist-title").text()).toContain(
      postData.title
    );
  });
});
