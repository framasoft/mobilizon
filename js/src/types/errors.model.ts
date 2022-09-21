import { Operation, NextLink } from "@apollo/client/core";
import { NetworkError } from "@apollo/client/errors";
import { ExecutionResult, GraphQLError } from "graphql";

export declare class AbsintheGraphQLError extends GraphQLError {
  field?: string;
  code?: string;
  status_code?: number;
}
export declare type AbsintheGraphQLErrors = ReadonlyArray<AbsintheGraphQLError>;

export interface ErrorResponse {
  graphQLErrors?: AbsintheGraphQLErrors;
  networkError?: NetworkError;
  response?: ExecutionResult;
  operation: Operation;
  forward: NextLink;
}
