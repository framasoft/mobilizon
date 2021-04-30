import { SEARCH_PERSONS } from "@/graphql/search";
import { VueRenderer } from "@tiptap/vue-2";
import tippy from "tippy.js";
import MentionList from "./MentionList.vue";
import ApolloClient from "apollo-client";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import apolloProvider from "@/vue-apollo";

const client = apolloProvider.defaultClient as ApolloClient<NormalizedCacheObject>;

const mentionOptions: Partial<any> = {
  HTMLAttributes: {
    class: "mention",
  },
  suggestion: {
    items: async (query: string) => {
      const result = await client.query({
        query: SEARCH_PERSONS,
        variables: {
          searchText: query,
        },
      });
      // TipTap doesn't handle async for onFilter, hence the following line.
      return result.data.searchPersons.elements;
    },
    render: () => {
      let component: VueRenderer;
      let popup: any;

      return {
        onStart: (props: any) => {
          component = new VueRenderer(MentionList, {
            parent: this,
            propsData: props,
          });

          popup = tippy("body", {
            getReferenceClientRect: props.clientRect,
            appendTo: () => document.body,
            content: component.element,
            showOnCreate: true,
            interactive: true,
            trigger: "manual",
            placement: "bottom-start",
          });
        },
        onUpdate(props: any) {
          component.updateProps(props);

          popup[0].setProps({
            getReferenceClientRect: props.clientRect,
          });
        },
        // onKeyDown(props: any) {
        // return component.ref?.onKeyDown(props);
        // },
        onExit() {
          popup[0].destroy();
          component.destroy();
        },
      };
    },
  },
};

export default mentionOptions;
