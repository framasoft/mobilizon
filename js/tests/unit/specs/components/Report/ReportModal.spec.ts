import { config, createLocalVue, mount } from "@vue/test-utils";
import ReportModal from "@/components/Report/ReportModal.vue";
import Buefy from "buefy";

const localVue = createLocalVue();
localVue.use(Buefy);
config.mocks.$t = (key: string): string => key;

const propsData = {
  onConfirm: jest.fn(),
};

const generateWrapper = (customPropsData: Record<string, unknown> = {}) => {
  return mount(ReportModal, {
    localVue,
    propsData: {
      ...propsData,
      ...customPropsData,
    },
  });
};

beforeEach(() => {
  jest.resetAllMocks();
});

describe("ReportModal", () => {
  it("renders report modal with basic informations and submits it", async () => {
    const wrapper = generateWrapper();

    expect(wrapper.find(".modal-card-head").exists()).toBe(false);

    expect(wrapper.find(".media-content").text()).not.toContain(
      "The content came from another server. Transfer an anonymous copy of the report?"
    );

    expect(
      wrapper.find("footer.modal-card-foot button:first-child").text()
    ).toBe("Cancel");

    const submit = wrapper.find("footer.modal-card-foot button.is-primary");

    expect(submit.text()).toBe("Send the report");

    const textarea = wrapper.find("textarea");
    textarea.setValue("some comment with my report");

    submit.trigger("click");

    await localVue.nextTick();
    expect(wrapper.emitted().close).toBeTruthy();

    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledWith(
      "some comment with my report",
      false
    );
  });

  it("renders report modal and shows an inline comment if it's provided", async () => {
    const wrapper = generateWrapper({
      comment: {
        actor: { preferredUsername: "author", name: "I am the comment author" },
        text: "this is my <b>comment</b> that will be reported",
      },
    });

    const commentContainer = wrapper.find("article.media");
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

    expect(wrapper.find(".media-content").text()).toContain(
      "The content came from another server. Transfer an anonymous copy of the report?"
    );

    const submit = wrapper.find("footer.modal-card-foot button.is-primary");
    submit.trigger("click");
    await localVue.nextTick();

    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledWith("", false);
  });

  it("renders report modal with with a remote content and accept to forward", async () => {
    const wrapper = generateWrapper({ outsideDomain: "somewhere.else" });

    expect(wrapper.find(".media-content").text()).toContain(
      "The content came from another server. Transfer an anonymous copy of the report?"
    );

    const switchButton = wrapper.find('input[type="checkbox"]');
    switchButton.trigger("click");

    const submit = wrapper.find("footer.modal-card-foot button.is-primary");
    submit.trigger("click");
    await localVue.nextTick();

    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.$props.onConfirm).toHaveBeenCalledWith("", true);
  });

  it("renders report modal custom title and buttons", async () => {
    const wrapper = generateWrapper({
      title: "want to report something?",
      cancelText: "nah",
      confirmText: "report!",
    });

    expect(wrapper.find(".modal-card-head .modal-card-title").text()).toBe(
      "want to report something?"
    );

    expect(
      wrapper.find("footer.modal-card-foot button:first-child").text()
    ).toBe("nah");

    expect(
      wrapper.find("footer.modal-card-foot button.is-primary").text()
    ).toBe("report!");
  });
});
