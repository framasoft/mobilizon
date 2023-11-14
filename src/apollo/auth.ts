import { AUTH_ACCESS_TOKEN } from "@/constants";
import { ApolloLink } from "@apollo/client/core";

export function generateTokenHeader() {
  const token = localStorage.getItem(AUTH_ACCESS_TOKEN);

  return token ? `Bearer ${token}` : null;
}

const authMiddleware = new ApolloLink((operation, forward) => {
  // add the authorization to the headers
  operation.setContext({
    headers: {
      authorization: generateTokenHeader(),
    },
  });

  if (forward) return forward(operation);

  return null;
});

export { authMiddleware };
