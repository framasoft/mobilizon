export const currentUser = {
  defaults: {
    currentUser: {
      __typename: 'CurrentUser',
      id: null,
      email: null,
      isLoggedIn: false,
    },
  },

  resolvers: {
    Mutation: {
      updateCurrentUser: (_, { id, email, isLoggedIn }, { cache }) => {
        const data = {
          currentUser: {
            id,
            email,
            isLoggedIn,
            __typename: 'CurrentUser',
          },
        };

        cache.writeData({ data });
      },
    },
  },
};
