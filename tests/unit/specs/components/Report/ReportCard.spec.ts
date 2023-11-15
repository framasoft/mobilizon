import { mount } from "@vue/test-utils";
import ReportCard from "@/components/Report/ReportCard.vue";
import { ActorType } from "@/types/enums";
import { describe, expect, it } from "vitest";

const reportData = {
  id: "1",
  content: "My content",
  insertedAt: "2020-12-02T09:01:20.873Z",
  reporter: {
    preferredUsername: "John Snow",
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
    propsData: {
      report: { ...reportData, ...customReportData },
    },
  });
};

describe("ReportCard", () => {
  it("renders report card with basic informations", () => {
    const wrapper = generateWrapper();

    expect(wrapper.find(".flex.gap-1 div p:first-child").text()).toBe(
      reportData.reported.name
    );

    expect(wrapper.find(".reported_by span:first-child").text()).toBe(
      `Reported by John Snow`
    );
  });

  it("renders report card with with a remote reporter", () => {
    const wrapper = generateWrapper({
      reporter: { domain: "somewhere.else", type: ActorType.APPLICATION },
    });

    expect(wrapper.find(".reported_by span:first-child").text()).toBe(
      "Reported by someone on somewhere.else"
    );
  });
});
