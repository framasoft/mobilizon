import { UPLOAD_MEDIA } from "@/graphql/upload";
import apolloProvider from "@/vue-apollo";
import ApolloClient from "apollo-client";
import { NormalizedCacheObject } from "apollo-cache-inmemory";
import { Plugin } from "prosemirror-state";
import { EditorView } from "prosemirror-view";
import Image from "@tiptap/extension-image";

/* eslint-disable class-methods-use-this */

const CustomImage = Image.extend({
  name: "image",
  addAttributes() {
    return {
      src: {
        default: null,
      },
      alt: {
        default: null,
      },
      title: {
        default: null,
      },
      "data-media-id": {
        default: null,
      },
    };
  },
  addProseMirrorPlugins() {
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
              const client =
                apolloProvider.defaultClient as ApolloClient<NormalizedCacheObject>;

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
  },
});

export default CustomImage;
