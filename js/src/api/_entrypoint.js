/**
 * Host of the instance
 *
 * Required
 *
 * Example: framameet.org
 */
export const MOBILIZON_INSTANCE_HOST = process.env.MOBILIZON_INSTANCE_HOST;

/**
 * URL on which the API is. "/api" will be added at the end
 *
 * Required
 *
 * Example: https://framameet.org
 */
export const GRAPHQL_API_ENDPOINT = process.env.GRAPHQL_API_ENDPOINT;

/**
 * URL with path on which the API is. Replaces GRAPHQL_API_ENDPOINT if used
 *
 * Optional
 *
 * Example: https://framameet.org/api
 */
export const GRAPHQL_API_FULL_PATH = process.env.GRAPHQL_API_FULL_PATH;
