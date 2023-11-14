import { UPLOAD_MEDIA } from "@/graphql/upload";
import { apolloClient } from "@/vue-apollo";
import { Plugin } from "prosemirror-state";
import { EditorView } from "prosemirror-view";
import Image from "@tiptap/extension-image";
import { provideApolloClient, useMutation } from "@vue/apollo-composable";

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
            drop(view: EditorView, event: Event) {
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

              images.forEach((image) => {
                const { onDone, onError } = provideApolloClient(apolloClient)(
                  () =>
                    useMutation<{ uploadMedia: { url: string; id: string } }>(
                      UPLOAD_MEDIA,
                      () => ({
                        variables: {
                          file: image,
                          name: image.name,
                        },
                      })
                    )
                );

                onDone(({ data }) => {
                  const node = schema.nodes.image.create({
                    src: data?.uploadMedia.url,
                    "data-media-id": data?.uploadMedia.id,
                  });
                  const transaction = view.state.tr.insert(
                    coordinates.pos,
                    node
                  );
                  view.dispatch(transaction);
                });

                onError((error) => {
                  console.error(error);
                  return false;
                });
              });
              return true;
            },
          },
        },
      }),
    ];
  },
});

export default CustomImage;
