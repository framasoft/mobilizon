export const loginMock = {
  email: "some@email.tld",
  password: "somepassword",
};

export const loginResponseMock = {
  data: {
    login: {
      __typename: "Login",
      accessToken: "some access token",
      refreshToken: "some refresh token",
      user: {
        __typename: "User",
        email: "some@email.tld",
        id: "1",
        role: "ADMINISTRATOR",
      },
    },
  },
};
