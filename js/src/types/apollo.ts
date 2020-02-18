import { ServerError, ServerParseError } from "apollo-link-http-common";

function isServerError(
  err: Error | ServerError | ServerParseError | undefined
): err is ServerError {
  return !!err && (err as ServerError).statusCode !== undefined;
}

export { isServerError };
