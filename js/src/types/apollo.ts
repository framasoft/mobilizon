import { GraphQLError } from "graphql/error/GraphQLError";

export class AbsintheGraphQLError extends GraphQLError {
  readonly field: string | undefined;
}
