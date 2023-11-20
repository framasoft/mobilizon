import { GraphQLError } from "graphql/error/GraphQLError";

export class AbsintheGraphQLError extends GraphQLError {
  readonly field: string | undefined;
}

export type TypeNamed<T extends Record<string, any>> = T & {
  __typename: string;
};
