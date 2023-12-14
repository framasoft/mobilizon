import { split } from "@apollo/client/core";
import { RetryLink } from "@apollo/client/link/retry";
import { getMainDefinition } from "@apollo/client/utilities";
import absintheSocketLink from "./absinthe-socket-link";
import { authMiddleware } from "./auth";
import errorLink from "./error-link";
import { uploadLink } from "./absinthe-upload-socket-link";

let link;

// The Absinthe socket Apollo link relies on an old library
// (@jumpn/utils-composite) which itself relies on an old
// Babel version, which is incompatible with Histoire.
// We just don't use the absinthe apollo socket link
// in this case.
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
if (!import.meta.env.VITE_HISTOIRE_ENV) {
  // const absintheSocketLink = await import("./absinthe-socket-link");

  link = split(
    // split based on operation type
    ({ query }) => {
      const definition = getMainDefinition(query);
      return (
        definition.kind === "OperationDefinition" &&
        definition.operation === "subscription"
      );
    },
    absintheSocketLink,
    uploadLink
  );
}

const retryLink = new RetryLink();

export const fullLink = retryLink
  .concat(errorLink)
  .concat(authMiddleware)
  .concat(link ?? uploadLink);
