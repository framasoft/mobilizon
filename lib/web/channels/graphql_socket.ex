defmodule Mobilizon.Web.GraphQLSocket do
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: Mobilizon.GraphQL.Schema

  alias Mobilizon.Applications.Application, as: AuthApplication
  alias Mobilizon.Applications.ApplicationToken
  alias Mobilizon.Users.User

  @spec connect(map, Phoenix.Socket.t()) :: {:ok, Phoenix.Socket.t()} | :error
  def connect(%{"token" => token}, socket) do
    with {:ok, authed_socket} <-
           Guardian.Phoenix.Socket.authenticate(socket, Mobilizon.Web.Auth.Guardian, token),
         resource <- Guardian.Phoenix.Socket.current_resource(authed_socket) do
      {:ok, set_context(authed_socket, resource)}
    else
      {:error, _} ->
        :error
    end
  end

  def connect(_args, _socket), do: :error

  @spec id(Phoenix.Socket.t()) :: String.t() | nil
  def id(%Phoenix.Socket{assigns: assigns}) do
    context = Keyword.get(assigns.absinthe.opts, :context)
    current_user = Map.get(context, :current_user)

    if current_user do
      "user_socket:#{current_user.id}"
    else
      nil
    end
  end

  @spec set_context(Phoenix.Socket.t(), User.t() | ApplicationToken.t()) :: Phoenix.Socket.t()
  defp set_context(socket, %User{} = user) do
    Absinthe.Phoenix.Socket.put_options(socket,
      context: %{
        current_user: user
      }
    )
  end

  defp set_context(
         socket,
         %ApplicationToken{user: %User{} = user, application: %AuthApplication{} = app} =
           app_token
       ) do
    Absinthe.Phoenix.Socket.put_options(socket,
      context: %{
        current_auth_app_token: app_token,
        current_auth_app: app,
        current_user: user
      }
    )
  end
end
