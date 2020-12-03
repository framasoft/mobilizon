import { config, createLocalVue, mount } from "@vue/test-utils";
import ReportCard from "@/components/Report/ReportCard.vue";
import Buefy from "buefy";
import { ActorType } from "@/types/enums";

const localVue = createLocalVue();
localVue.use(Buefy);
config.mocks.$t = (key: string): string => key;

const reportData = {
  id: "1",
  content: "My content",
  insertedAt: "2020-12-02T09:01:20.873Z",
  reporter: {
    preferredUsername: "author",
    domain: null,
    name: "Reporter of Things",
    type: ActorType.PERSON,
  },
  reported: {
    preferredUsername: "my-awesome-group",
    domain: null,
    name: "My Awesome Group",
  },
};

const generateWrapper = (customReportData: Record<string, unknown> = {}) => {
  return mount(ReportCard, {
    localVue,
    propsData: {
      report: { ...reportData, ...customReportData },
    },
  });
};

describe("ReportCard", () => {
  it("renders report card with basic informations", () => {
    const wrapper = generateWrapper();

    expect(wrapper.find(".media-content .title").text()).toBe(
      reportData.reported.name
    );

    expect(wrapper.find(".media-content .subtitle").text()).toBe(
      `@${reportData.reported.preferredUsername}`
    );

    expect(wrapper.find(".is-one-quarter-desktop span").text()).toBe(
      `Reported by {reporter}`
    );
  });

  it("renders report card with with a remote reporter", () => {
    const wrapper = generateWrapper({
      reporter: { domain: "somewhere.else", type: ActorType.APPLICATION },
    });

    expect(wrapper.find(".is-one-quarter-desktop span").text()).toBe(
      "Reported by someone on {domain}"
    );
  });
});
