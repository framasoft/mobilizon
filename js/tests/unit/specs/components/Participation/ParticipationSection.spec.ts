import { config, mount, VueWrapper } from "@vue/test-utils";
import ParticipationSection from "@/components/Participation/ParticipationSection.vue";
import { createRouter, createWebHistory, Router } from "vue-router";
import { routes } from "@/router";
import { CommentModeration, EventJoinOptions } from "@/types/enums";
import { InMemoryCache } from "@apollo/client/cache";
import { beforeEach, describe, expect, it } from "vitest";
import Oruga from "@oruga-ui/oruga-next";
import FloatingVue from "floating-vue";

config.global.plugins.push(Oruga);
config.global.plugins.push(FloatingVue);

let router: Router;

beforeEach(async () => {
  router = createRouter({
    history: createWebHistory(),
    routes: routes,
  });

  // await router.isReady();
});
const eventData = {
  id: "1",
  uuid: "e37910ea-fd5a-4756-7634-00971f3f4107",
  options: {
    commentModeration: CommentModeration.ALLOW_ALL,
  },
  beginsOn: new Date("2089-12-04T09:21:25Z"),
  endsOn: new Date("2089-12-04T11:21:25Z"),
};

describe("ParticipationSection", () => {
  let wrapper: VueWrapper;

  const generateWrapper = (customProps: Record<string, unknown> = {}) => {
    wrapper = mount(ParticipationSection, {
      stubs: {
        ParticipationButton: true,
      },
      props: {
        participation: null,
        event: eventData,
        anonymousParticipation: null,
        currentActor: { id: "5" },
        identities: [],
        anonymousParticipationConfig: {
          allowed: true,
        },
        ...customProps,
      },
      global: {
        plugins: [router],
      },
    });
  };

  it("renders the participation section with minimal data", async () => {
    generateWrapper();
    await wrapper.vm.$nextTick();

    expect(wrapper.exists()).toBe(true);

    expect(wrapper.find(".event-participation").exists()).toBeTruthy();

    // TODO: Move to participation button test
    // const participationButton = wrapper.find(
    //   ".event-participation .participation-button a.button.is-large.is-primary"
    // );
    // expect(participationButton.attributes("href")).toBe(
    //   `/events/${eventData.uuid}/participate/with-account`
    // );

    // expect(participationButton.text()).toBe("Participate");
  });

  it("renders the participation section with existing confimed anonymous participation", async () => {
    generateWrapper({ anonymousParticipation: true });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously"
    );

    const cancelAnonymousParticipationButton = wrapper.find(
      ".event-participation > button.o-btn--text"
    );
    expect(cancelAnonymousParticipationButton.text()).toBe(
      "Cancel anonymous participation"
    );

    wrapper.find(".event-participation small span").trigger("click");
    expect(
      wrapper
        .findComponent({ ref: "anonymous-participation-modal" })
        .isVisible()
    ).toBeTruthy();

    cancelAnonymousParticipationButton.trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted("cancel-anonymous-participation")).toBeTruthy();
  });

  it("renders the participation section with existing confimed anonymous participation but event moderation", async () => {
    generateWrapper({
      anonymousParticipation: true,
      event: { ...eventData, joinOptions: EventJoinOptions.RESTRICTED },
    });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously"
    );

    const cancelAnonymousParticipationButton = wrapper.find(
      ".event-participation > button.o-btn--text"
    );
    expect(cancelAnonymousParticipationButton.text()).toBe(
      "Cancel anonymous participation"
    );

    wrapper.find(".event-participation small span").trigger("click");

    await wrapper.vm.$nextTick();
    const modal = wrapper.findComponent({
      ref: "anonymous-participation-modal",
    });
    expect(modal.isVisible()).toBeTruthy();
    expect(modal.find(".o-notification--primary").text()).toBe(
      "As the event organizer has chosen to manually validate participation requests, your participation will be really confirmed only once you receive an email stating it's being accepted."
    );

    cancelAnonymousParticipationButton.trigger("click");
    await wrapper.vm.$nextTick();
    expect(wrapper.emitted("cancel-anonymous-participation")).toBeTruthy();
  });

  it("renders the participation section with existing unconfirmed anonymous participation", async () => {
    generateWrapper({ anonymousParticipation: false });

    expect(wrapper.find(".event-participation > small").text()).toContain(
      "You are participating in this event anonymously but didn't confirm participation"
    );
  });

  it("renders the participation section but the event is already passed", async () => {
    generateWrapper({
      event: {
        ...eventData,
        beginsOn: "2020-12-02T10:52:56Z",
        endsOn: "2020-12-03T10:52:56Z",
      },
    });

    expect(wrapper.find(".event-participation").exists()).toBeFalsy();
    expect(wrapper.find("button.o-btn--primary").text()).toBe(
      "Event already passed"
    );
  });
});
