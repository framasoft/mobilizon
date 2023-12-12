import { logout } from "@/utils/auth";
import { onError } from "@apollo/client/link/error";
import { fromPromise } from "@apollo/client/core";
import { refreshAccessToken } from "./utils";
import { GraphQLError } from "graphql";
import { generateTokenHeader } from "./auth";

let isRefreshing = false;
let pendingRequests: any[] = [];

const resolvePendingRequests = () => {
  console.debug("resolving pending requests");
  pendingRequests.map((callback) => {
    console.debug("calling callback", callback);
    return callback();
  });
  console.debug("emptying pending requests after resolving them all");
  pendingRequests = [];
};

const isAuthError = (graphQLError: GraphQLError | undefined) => {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  return graphQLError && [403, 401].includes(graphQLError.status_code);
};

const errorLink = onError(
  ({ graphQLErrors, networkError, forward, operation }) => {
    if (graphQLErrors) {
      graphQLErrors.map(
        (graphQLError: GraphQLError & { status_code?: number }) => {
          if (graphQLError?.status_code !== 401) {
            console.debug(
              `[GraphQL error]: Message: ${graphQLError.message}, Location: ${graphQLError.locations}, Path: ${graphQLError.path}`
            );
          }
        }
      );
    }

    if (networkError) {
      console.error(`[Network error]: ${networkError}`);
      console.debug(JSON.stringify(networkError));
    }

    if (
      graphQLErrors?.some((graphQLError) => isAuthError(graphQLError)) ||
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      networkError === 401
    ) {
      console.debug("It's a authorization error (statusCode 401)");
      let forwardOperation;

      if (!isRefreshing) {
        console.debug("Setting isRefreshing to true");
        isRefreshing = true;

        forwardOperation = fromPromise(
          refreshAccessToken()
            .then((res) => {
              if (res !== true) {
                // failed to refresh the token
                throw "Failed to refresh the token";
              }
              resolvePendingRequests();

              const context = operation.getContext();
              const oldHeaders = context.headers;

              operation.setContext({
                headers: {
                  ...oldHeaders,
                  authorization: generateTokenHeader(),
                },
              });
              return true;
            })
            .catch((e) => {
              console.debug("Something failed, let's logout", e);
              pendingRequests = [];
              // don't perform a logout since we don't have any working access/refresh tokens
              logout(false);
              return;
            })
            .finally(() => {
              isRefreshing = false;
            })
        ).filter((value) => Boolean(value));
      } else {
        console.debug(
          "Skipping refreshing as isRefreshing is already to true, adding requests to pending"
        );
        forwardOperation = fromPromise(
          new Promise((resolve) => {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            pendingRequests.push(() => resolve());
          })
        );
      }

      return forwardOperation.flatMap(() => forward(operation));
    }
  }
);

export default errorLink;
