import { SEARCH_PERSONS } from "@/graphql/search";
import { VueRenderer } from "@tiptap/vue-3";
import tippy from "tippy.js";
import MentionList from "./MentionList.vue";
import { apolloClient } from "@/vue-apollo";
import { IPerson } from "@/types/actor";
import pDebounce from "p-debounce";
import { MentionOptions } from "@tiptap/extension-mention";
import { Editor } from "@tiptap/core";
import { provideApolloClient, useQuery } from "@vue/apollo-composable";
import { Paginate } from "@/types/paginate";
import { onError } from "@apollo/client/link/error";

const fetchItems = (query: string): Promise<IPerson[]> => {
  return new Promise((resolve, reject) => {
    const { onResult } = provideApolloClient(apolloClient)(() => {
      return useQuery<{ searchPersons: Paginate<IPerson> }>(
        SEARCH_PERSONS,
        () => ({
          variables: {
            searchText: query,
          },
        })
      );
    });

    onResult(({ data }) => {
      resolve(data.searchPersons.elements);
    });

    onError(reject);
  });

  // // TipTap doesn't handle async for onFilter, hence the following line.
  // return result.data.searchPersons.elements;
};

const debouncedFetchItems = pDebounce(fetchItems, 200);

const mentionOptions: MentionOptions = {
  HTMLAttributes: {
    class: "mention",
    dir: "ltr",
  },
  renderLabel({ options, node }) {
    return `${options.suggestion.char}${node.attrs.label ?? node.attrs.id}`;
  },
  suggestion: {
    items: async ({
      query,
    }: {
      query: string;
      editor: Editor;
    }): Promise<IPerson[]> => {
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
          if (popup && popup[0]) {
            popup[0].destroy();
          }
          if (component) {
            component.destroy();
          }
        },
      };
    },
  },
};

export default mentionOptions;
