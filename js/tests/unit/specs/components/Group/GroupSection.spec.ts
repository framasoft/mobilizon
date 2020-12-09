import { config, createLocalVue, mount } from "@vue/test-utils";
import GroupSection from "@/components/Group/GroupSection.vue";
import Buefy from "buefy";
import VueRouter, { Location } from "vue-router";
import RouteName from "@/router/name";
import { routes } from "@/router";

const localVue = createLocalVue();
localVue.use(Buefy);
config.mocks.$t = (key: string): string => key;
localVue.use(VueRouter);
const router = new VueRouter({ routes, mode: "history" });

const groupPreferredUsername = "my_group";
const groupDomain = "remotedomain.net";
const groupUsername = `${groupPreferredUsername}@${groupDomain}`;

const defaultSlotText = "A list of elements";
const createSlotButtonText = "+ Post a public message";

type Props = {
  title?: string;
  icon?: string;
  privateSection?: boolean;
  route?: Location;
};

const baseProps: Props = {
  title: "My group section",
  icon: "bullhorn",
  route: {
    name: RouteName.POSTS,
    params: {
      preferredUsername: groupUsername,
    },
  },
};

const generateWrapper = (customProps: Props = {}) => {
  return mount(GroupSection, {
    localVue,
    router,
    propsData: { ...baseProps, ...customProps },
    slots: {
      default: `<div>${defaultSlotText}</div>`,
      create: `<router-link :to="{
                name: 'POST_CREATE',
                params: { preferredUsername: '${groupUsername}' },
              }"
              class="button is-primary"
              >{{ $t("${createSlotButtonText}") }}</router-link
            >`,
    },
  });
};

describe("GroupSection", () => {
  it("renders group section with basic informations", () => {
    const wrapper = generateWrapper({});

    expect(
      wrapper
        .find(".group-section-title h2 span.icon i")
        .classes(`mdi-${baseProps.icon}`)
    ).toBe(true);

    expect(wrapper.find(".group-section-title h2 span:last-child").text()).toBe(
      baseProps.title
    );

    expect(wrapper.find(".group-section-title a").attributes("href")).toBe(
      `/@${groupUsername}/p`
    );

    expect(wrapper.find(".group-section-title").classes("privateSection")).toBe(
      true
    );

    expect(wrapper.find(".main-slot div").text()).toBe(defaultSlotText);
    expect(wrapper.find(".create-slot a").text()).toBe(createSlotButtonText);
    expect(wrapper.find(".create-slot a").attributes("href")).toBe(
      `/@${groupUsername}/p/new`
    );
    expect(wrapper.html()).toMatchSnapshot();
  });

  it("renders public group section", () => {
    const wrapper = generateWrapper({ privateSection: false });

    expect(wrapper.find(".group-section-title").classes("privateSection")).toBe(
      false
    );
    expect(wrapper.html()).toMatchSnapshot();
  });
});
