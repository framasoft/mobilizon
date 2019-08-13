/**
 * Host of the instance
 *
 * Required
 *
 * Example: framameet.org
 */
export const MOBILIZON_INSTANCE_HOST = window.location.hostname;

/**
 * URL on which the API is. "/api" will be added at the end
 *
 * Required
 *
 * Example: https://framameet.org
 */
export const GRAPHQL_API_ENDPOINT = window.location.origin;

/**
 * URL with path on which the API is. Replaces GRAPHQL_API_ENDPOINT if used
 *
 * Optional
 *
 * Example: https://framameet.org/api
 */
export const GRAPHQL_API_FULL_PATH = `${window.location.origin}/api`;
