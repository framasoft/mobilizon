import { mount } from "@vue/test-utils";
import Tag from "@/components/Tag.vue";

const tagContent = "My tag";

const createComponent = () => {
  return mount(Tag, {
    slots: {
      default: tagContent,
    },
  });
};

it("renders a Vue component", () => {
  const wrapper = createComponent();

  expect(wrapper.exists()).toBe(true);
  expect(wrapper.find("span.tag span").text()).toEqual(tagContent);
});
