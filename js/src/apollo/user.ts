export const currentUser = {
  defaults: {
    currentUser: {
      __typename: 'CurrentUser',
      id: null,
      email: null,
    },
  },

  resolvers: {
    Mutation: {
      updateCurrentUser: (_, { id, email }, { cache }) => {
        const data = {
          currentUser: {
            id,
            email,
            __typename: 'CurrentUser',
          },
        };

        cache.writeData({ data });
      },
    },
  },
};
