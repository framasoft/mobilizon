defmodule Mobilizon.GraphQL.Error do
  @moduledoc """
  Module to handle errors in GraphQL
  """

  require Logger
  alias __MODULE__
  import Mobilizon.Web.Gettext

  defstruct [:code, :message, :status_code, :field]

  # Error Tuples
  # ------------
  # Regular errors
  def normalize({:error, reason}) do
    handle(reason)
  end

  # Ecto transaction errors
  def normalize({:error, _operation, reason, _changes}) do
    handle(reason)
  end

  # Unhandled errors
  def normalize(other) do
    handle(other)
  end

  # Handle Different Errors
  # -----------------------
  defp handle(code) when is_atom(code) do
    {status, message} = metadata(code)

    %Error{
      code: code,
      message: message,
      status_code: status
    }
  end

  defp handle(errors) when is_list(errors) do
    Enum.map(errors, &handle/1)
  end

  defp handle(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {err, _opts} -> err end)
    |> Enum.map(fn {k, v} ->
      %Error{
        code: :validation,
        message: v,
        field: k,
        status_code: 422
      }
    end)
  end

  defp handle(reason) when is_binary(reason) do
    %Error{
      code: :unknown_error,
      message: reason,
      status_code: 500
    }
  end

  # ... Handle other error types here ...
  defp handle(other) do
    Logger.error("Unhandled error term:\n#{inspect(other)}")
    handle(:unknown)
  end

  # Build Error Metadata
  # --------------------
  defp metadata(:unknown_resource), do: {400, dgettext("errors", "Unknown Resource")}
  defp metadata(:invalid_argument), do: {400, dgettext("errors", "Invalid arguments passed")}
  defp metadata(:unauthenticated), do: {401, dgettext("errors", "You need to be logged in")}

  defp metadata(:password_hash_missing),
    do: {401, dgettext("errors", "Reset your password to login")}

  defp metadata(:incorrect_password), do: {401, dgettext("errors", "Invalid credentials")}

  defp metadata(:unauthorized),
    do: {403, dgettext("errors", "You don't have permission to do this")}

  defp metadata(:not_found), do: {404, dgettext("errors", "Resource not found")}
  defp metadata(:user_not_found), do: {404, dgettext("errors", "User not found")}
  defp metadata(:post_not_found), do: {404, dgettext("errors", "Post not found")}
  defp metadata(:event_not_found), do: {404, dgettext("errors", "Event not found")}
  defp metadata(:group_not_found), do: {404, dgettext("errors", "Group not found")}
  defp metadata(:resource_not_found), do: {404, dgettext("errors", "Resource not found")}
  defp metadata(:discussion_not_found), do: {404, dgettext("errors", "Discussion not found")}
  defp metadata(:unknown), do: {500, dgettext("errors", "Something went wrong")}

  defp metadata(code) do
    Logger.warn("Unhandled error code: #{inspect(code)}")
    {422, to_string(code)}
  end
end
