import { config, mount } from "@vue/test-utils";
import ReportModal from "@/components/Report/ReportModal.vue";
import { vi, beforeEach, describe, it, expect } from "vitest";

import Oruga from "@oruga-ui/oruga-next";

config.global.plugins.push(Oruga);

const propsData = {
  onConfirm: vi.fn(),
};

const generateWrapper = (customPropsData: Record<string, unknown> = {}) => {
  return mount(ReportModal, {
    props: {
      ...propsData,
      ...customPropsData,
    },
  });
};

beforeEach(() => {
  vi.resetAllMocks();
});

describe("ReportModal", () => {
  it("renders report modal with basic informations and submits it", async () => {
    const wrapper = generateWrapper();

    expect(wrapper.find("header").exists()).toBe(false);

    expect(wrapper.find("section").text()).not.toContain(
      "The content came from another server. Transfer an anonymous copy of the report?"
    );

    expect(wrapper.find("footer button:first-child").text()).toBe("Cancel");

    const submit = wrapper.find("footer button.o-btn--primary");

    expect(submit.text()).toBe("Send the report");

    const textarea = wrapper.find("textarea");
    textarea.setValue("some comment with my report");

    submit.trigger("click");

    await wrapper.vm.$nextTick();
    expect(wrapper.emitted().close).toBeTruthy();

    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledWith(
      "some comment with my report",
      false
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders report modal and shows an inline comment if it's provided", async () => {
    const wrapper = generateWrapper({
      comment: {
        actor: { preferredUsername: "author", name: "I am the comment author" },
        text: "this is my <b>comment</b> that will be reported",
      },
    });

    const commentContainer = wrapper.find("article");
    expect(commentContainer.find("strong").text()).toContain(
      "I am the comment author"
    );
    expect(commentContainer.find("small").text()).toContain("author");
    expect(commentContainer.find("p").html()).toContain(
      "this is my <b>comment</b> that will be reported"
    );
  });

  it("renders report modal with with a remote content", async () => {
    const wrapper = generateWrapper({ outsideDomain: "somewhere.else" });

    expect(wrapper.find(".control p").text()).toContain(
      "The content came from another server. Transfer an anonymous copy of the report?"
    );

    const submit = wrapper.find("footer button.o-btn--primary");
    submit.trigger("click");
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledWith("", false);
  });

  it("renders report modal with with a remote content and accept to forward", async () => {
    const wrapper = generateWrapper({ outsideDomain: "somewhere.else" });

    expect(wrapper.find(".control p").text()).toContain(
      "The content came from another server. Transfer an anonymous copy of the report?"
    );

    const switchButton = wrapper.find('input[type="checkbox"]');
    switchButton.setValue(true);

    const submit = wrapper.find("footer button.o-btn--primary");
    submit.trigger("click");
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledWith("", true);
  });

  it("renders report modal custom title and buttons", async () => {
    const wrapper = generateWrapper({
      title: "want to report something?",
      cancelText: "nah",
      confirmText: "report!",
    });

    expect(wrapper.find("header h2").text()).toBe("want to report something?");

    expect(wrapper.find("footer button:first-child").text()).toBe("nah");

    expect(wrapper.find("footer button.o-btn--primary").text()).toBe("report!");
  });
});
