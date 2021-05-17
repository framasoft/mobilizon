import { SEARCH_PERSONS } from "@/graphql/search";
import { VueRenderer } from "@tiptap/vue-2";
import tippy from "tippy.js";
import MentionList from "./MentionList.vue";
import ApolloClient from "apollo-client";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import apolloProvider from "@/vue-apollo";
import { IPerson } from "@/types/actor";
import pDebounce from "p-debounce";

const client =
  apolloProvider.defaultClient as ApolloClient<NormalizedCacheObject>;

const fetchItems = async (query: string): Promise<IPerson[]> => {
  const result = await client.query({
    query: SEARCH_PERSONS,
    variables: {
      searchText: query,
    },
  });
  // TipTap doesn't handle async for onFilter, hence the following line.
  return result.data.searchPersons.elements;
};

const debouncedFetchItems = pDebounce(fetchItems, 200);

const mentionOptions: Partial<any> = {
  HTMLAttributes: {
    class: "mention",
  },
  suggestion: {
    items: async (query: string): Promise<IPerson[]> => {
      if (query === "") {
        return [];
      }
      return await debouncedFetchItems(query);
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
        onKeyDown(props: any) {
          // eslint-disable-next-line @typescript-eslint/ban-ts-comment
          // @ts-ignore
          return component.ref?.onKeyDown(props);
        },
        onExit() {
          popup[0].destroy();
          component.destroy();
        },
      };
    },
  },
};

export default mentionOptions;
