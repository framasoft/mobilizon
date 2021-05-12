import { ServerParseError } from "@apollo/client/link/http";
import { ServerError } from "@apollo/client/link/utils";

function isServerError(
  err: Error | ServerError | ServerParseError | undefined
): err is ServerError {
  return !!err && (err as ServerError).statusCode !== undefined;
}

export { isServerError };
