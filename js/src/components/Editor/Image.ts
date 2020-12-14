// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
import { Node } from "tiptap";
import { UPLOAD_MEDIA } from "@/graphql/upload";
import apolloProvider from "@/vue-apollo";
import ApolloClient from "apollo-client";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import { NodeType, NodeSpec } from "prosemirror-model";
import { EditorState, Plugin, TextSelection } from "prosemirror-state";
import { DispatchFn } from "tiptap-commands";
import { EditorView } from "prosemirror-view";

/* eslint-disable class-methods-use-this */

export default class Image extends Node {
  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  get name() {
    return "image";
  }

  get schema(): NodeSpec {
    return {
      inline: true,
      attrs: {
        src: {},
        alt: {
          default: null,
        },
        title: {
          default: null,
        },
        "data-media-id": {},
      },
      group: "inline",
      draggable: true,
      parseDOM: [
        {
          tag: "img",
          getAttrs: (dom: any) => ({
            src: dom.getAttribute("src"),
            title: dom.getAttribute("title"),
            alt: dom.getAttribute("alt"),
            "data-media-id": dom.getAttribute("data-media-id"),
          }),
        },
      ],
      toDOM: (node: any) => ["img", node.attrs],
    };
  }

  commands({ type }: { type: NodeType }): any {
    return (attrs: { [key: string]: string }) => (
      state: EditorState,
      dispatch: DispatchFn
    ) => {
      const { selection }: { selection: TextSelection } = state;
      const position = selection.$cursor
        ? selection.$cursor.pos
        : selection.$to.pos;
      const node = type.create(attrs);
      const transaction = state.tr.insert(position, node);
      dispatch(transaction);
    };
  }

  // eslint-disable-next-line @typescript-eslint/explicit-module-boundary-types
  get plugins() {
    return [
      new Plugin({
        props: {
          handleDOMEvents: {
            drop(view: EditorView<any>, event: Event) {
              const realEvent = event as DragEvent;
              if (
                !(
                  realEvent.dataTransfer &&
                  realEvent.dataTransfer.files &&
                  realEvent.dataTransfer.files.length
                )
              ) {
                return false;
              }

              const images = Array.from(realEvent.dataTransfer.files).filter(
                (file: any) =>
                  /image/i.test(file.type) && !/svg/i.test(file.type)
              );

              if (images.length === 0) {
                return false;
              }

              realEvent.preventDefault();

              const { schema } = view.state;
              const coordinates = view.posAtCoords({
                left: realEvent.clientX,
                top: realEvent.clientY,
              });
              if (!coordinates) return false;
              const client = apolloProvider.defaultClient as ApolloClient<NormalizedCacheObject>;

              try {
                images.forEach(async (image) => {
                  const { data } = await client.mutate({
                    mutation: UPLOAD_MEDIA,
                    variables: {
                      file: image,
                      name: image.name,
                    },
                  });
                  const node = schema.nodes.image.create({
                    src: data.uploadMedia.url,
                    "data-media-id": data.uploadMedia.id,
                  });
                  const transaction = view.state.tr.insert(
                    coordinates.pos,
                    node
                  );
                  view.dispatch(transaction);
                });
                return true;
              } catch (error) {
                console.error(error);
                return false;
              }
            },
          },
        },
      }),
    ];
  }
}
