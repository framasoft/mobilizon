import { Socket as PhoenixSocket } from "phoenix";
import { create } from "@framasoft/socket";
import { createAbsintheSocketLink } from "@framasoft/socket-apollo-link";
import { AUTH_ACCESS_TOKEN } from "@/constants";
import { GRAPHQL_API_ENDPOINT } from "@/api/_entrypoint";

const httpServer = GRAPHQL_API_ENDPOINT || "http://localhost:4000";

const webSocketPrefix = import.meta.env.PROD ? "wss" : "ws";
const wsEndpoint = `${webSocketPrefix}${httpServer.substring(
  httpServer.indexOf(":")
)}/graphql_socket`;

const phoenixSocket = new PhoenixSocket(wsEndpoint, {
  params: () => {
    const token = localStorage.getItem(AUTH_ACCESS_TOKEN);
    if (token) {
      return { token };
    }
    return {};
  },
});

const absintheSocket = create(phoenixSocket);
export default createAbsintheSocketLink(absintheSocket);
