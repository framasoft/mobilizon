// @ts-nocheck
import { Node } from "tiptap";
import { UPLOAD_PICTURE } from "@/graphql/upload";
import apolloProvider from "@/vue-apollo";
import ApolloClient from "apollo-client";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import { NodeType, NodeSpec } from "prosemirror-model";
import { EditorState, Plugin, TextSelection } from "prosemirror-state";
import { DispatchFn } from "tiptap-commands";
import { EditorView } from "prosemirror-view";

/* eslint-disable class-methods-use-this */

export default class Image extends Node {
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
      },
      group: "inline",
      draggable: true,
      parseDOM: [
        {
          tag: "img[src]",
          getAttrs: (dom: any) => ({
            src: dom.getAttribute("src"),
            title: dom.getAttribute("title"),
            alt: dom.getAttribute("alt"),
          }),
        },
      ],
      toDOM: (node: any) => ["img", node.attrs],
    };
  }

  commands({ type }: { type: NodeType }): any {
    return (attrs: { [key: string]: string }) => (state: EditorState, dispatch: DispatchFn) => {
      const { selection }: { selection: TextSelection } = state;
      const position = selection.$cursor ? selection.$cursor.pos : selection.$to.pos;
      const node = type.create(attrs);
      const transaction = state.tr.insert(position, node);
      dispatch(transaction);
    };
  }

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
                (file: any) => /image/i.test(file.type) && !/svg/i.test(file.type)
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
              const editorElem = document.getElementById("tiptab-editor");
              const actorId = editorElem && editorElem.dataset.actorId;

              try {
                images.forEach(async (image) => {
                  const { data } = await client.mutate({
                    mutation: UPLOAD_PICTURE,
                    variables: {
                      actorId,
                      file: image,
                      name: image.name,
                    },
                  });
                  const node = schema.nodes.image.create({ src: data.uploadPicture.url });
                  const transaction = view.state.tr.insert(coordinates.pos, node);
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
