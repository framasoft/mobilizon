import { config, createLocalVue, mount } from "@vue/test-utils";
import PostElementItem from "@/components/Post/PostElementItem.vue";
import { formatDateTimeString } from "@/filters/datetime";
import Buefy from "buefy";
import VueRouter from "vue-router";
import { routes } from "@/router";
import { PostVisibility } from "@/types/enums";

const localVue = createLocalVue();
localVue.use(Buefy);
localVue.use(VueRouter);
const router = new VueRouter({ routes, mode: "history" });
localVue.filter("formatDateTimeString", formatDateTimeString);
config.mocks.$t = (key: string): string => key;

const postData = {
  id: "1",
  slug: "my-blog-post-some-uuid",
  title: "My Blog Post",
  body: "My content",
  insertedAt: "2020-12-02T09:01:20.873Z",
  visibility: PostVisibility.PUBLIC,
  author: {
    preferredUsername: "author",
    domain: "remote-domain.tld",
    name: "Author",
  },
  attributedTo: {
    preferredUsername: "my-awesome-group",
    domain: null,
    name: "My Awesome Group",
  },
};

const generateWrapper = (
  customPostData: Record<string, unknown> = {},
  isCurrentActorMember = false
) => {
  return mount(PostElementItem, {
    localVue,
    router,
    propsData: {
      post: { ...postData, ...customPostData },
      isCurrentActorMember,
    },
  });
};

describe("PostElementItem", () => {
  it("renders post with basic informations", () => {
    const wrapper = generateWrapper();
    expect(wrapper.html()).toMatchSnapshot();

    expect(
      wrapper.find("a.post-minimalist-card-wrapper").attributes("href")
    ).toBe(`/p/${postData.slug}`);

    expect(wrapper.find(".post-minimalist-title").text()).toContain(
      postData.title
    );
    expect(wrapper.find(".metadata").text()).toContain(
      formatDateTimeString(postData.insertedAt, false)
    );

    expect(wrapper.find(".metadata small").text()).not.toContain("Public");
  });

  it("shows the author if actor is a group member", () => {
    const wrapper = generateWrapper({}, true);
    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find(".metadata").text()).toContain(`Created by {username}`);
  });

  it("shows the draft tag if post is a draft", () => {
    const wrapper = generateWrapper({ draft: true });
    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.findComponent({ name: "b-tag" }).exists()).toBe(true);
  });

  it("tells if the post is public when the actor is a group member", () => {
    const wrapper = generateWrapper({}, true);
    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find(".metadata small").text()).toContain("Public");
  });

  it("tells if the post is accessible only through link", () => {
    const wrapper = generateWrapper({ visibility: PostVisibility.UNLISTED });
    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find(".metadata small").text()).toContain(
      "Accessible through link"
    );
  });

  it("tells if the post is accessible only to members", () => {
    const wrapper = generateWrapper({ visibility: PostVisibility.PRIVATE });
    expect(wrapper.html()).toMatchSnapshot();

    expect(wrapper.find(".metadata small").text()).toContain(
      "Accessible only to members"
    );
  });
});
