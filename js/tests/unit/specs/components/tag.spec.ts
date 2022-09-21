import { mount } from "@vue/test-utils";
import Tag from "@/components/TagElement.vue";
import { it, expect } from "vitest";

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
  expect(wrapper.find("span").text()).toEqual(tagContent);
});
