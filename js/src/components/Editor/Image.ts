import { Node, Plugin } from 'tiptap';
import { UPLOAD_PICTURE } from '@/graphql/upload';
import { apolloProvider } from '@/vue-apollo';
import ApolloClient from 'apollo-client';
import { InMemoryCache } from 'apollo-cache-inmemory';

export default class Image extends Node {

  get name() {
    return 'image';
  }

  get schema() {
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
      group: 'inline',
      draggable: true,
      parseDOM: [
        {
          tag: 'img[src]',
          getAttrs: dom => ({
            src: dom.getAttribute('src'),
            title: dom.getAttribute('title'),
            alt: dom.getAttribute('alt'),
          }),
        },
      ],
      toDOM: node => ['img', node.attrs],
    };
  }

  commands({ type }) {
    return attrs => (state, dispatch) => {
      const { selection } = state;
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
            async drop(view, event: DragEvent) {
              if (!(event.dataTransfer && event.dataTransfer.files && event.dataTransfer.files.length)) {
                return;
              }

              const images = Array
                                .from(event.dataTransfer.files)
                                .filter((file: any) => (/image/i).test(file.type));

              if (images.length === 0) {
                return;
              }

              event.preventDefault();

              const { schema } = view.state;
              const coordinates = view.posAtCoords({ left: event.clientX, top: event.clientY });
              const client = apolloProvider.defaultClient as ApolloClient<InMemoryCache>;
              const editorElem = document.getElementById('tiptab-editor');
              const actorId = editorElem && editorElem.dataset.actorId;

              for (const image of images) {
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
              }
            },
          },
        },
      }),
    ];
  }

}
