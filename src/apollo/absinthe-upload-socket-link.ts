import fetch from "unfetch";
import { createLink } from "apollo-absinthe-upload-link";
import { GRAPHQL_API_ENDPOINT, GRAPHQL_API_FULL_PATH } from "@/api/_entrypoint";

// Endpoints
const httpServer = GRAPHQL_API_ENDPOINT || "http://localhost:4000";
const httpEndpoint = GRAPHQL_API_FULL_PATH || `${httpServer}/api`;

const customFetch = async (uri: string, options: any) => {
  const response = await fetch(uri, options);
  if (response.status >= 400) {
    return Promise.reject(response.status);
  }
  return response;
};

export const uploadLink = createLink({
  uri: httpEndpoint,
  fetch: customFetch,
});
