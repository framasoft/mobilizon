defmodule Mobilizon.Web.GraphQLSocket do
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: Mobilizon.GraphQL.Schema

  alias Mobilizon.Users.User

  def connect(%{"token" => token}, socket) do
    with {:ok, authed_socket} <-
           Guardian.Phoenix.Socket.authenticate(socket, Mobilizon.Web.Auth.Guardian, token),
         %User{} = user <- Guardian.Phoenix.Socket.current_resource(authed_socket) do
      authed_socket =
        Absinthe.Phoenix.Socket.put_options(socket,
          context: %{
            current_user: user
          }
        )

      {:ok, authed_socket}
    else
      {:error, _} ->
        :error
    end
  end

  def id(_socket), do: nil
end
