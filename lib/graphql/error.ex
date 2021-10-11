defmodule Mobilizon.GraphQL.Error do
  @moduledoc """
  Module to handle errors in GraphQL
  """

  require Logger
  alias __MODULE__
  alias Mobilizon.Web.Gettext, as: GettextBackend
  import Mobilizon.Web.Gettext, only: [dgettext: 2]

  @type t :: %{code: atom(), message: String.t(), status_code: pos_integer(), field: atom()}

  defstruct [:code, :message, :status_code, :field]

  @type error :: {:error, any()} | {:error, any(), any(), any()} | atom()

  @doc """
  Normalize an error to return `t`.
  """
  # Error Tuples
  # ------------
  # Regular errors
  @spec normalize(any()) :: t() | list(t())
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
    |> Ecto.Changeset.traverse_errors(&translate_error/1)
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

  # Translates an error message using gettext.
  defp translate_error({msg, opts}) do
    # Because error messages were defined within Ecto, we must
    # call the Gettext module passing our Gettext backend. We
    # also use the "errors" domain as translations are placed
    # in the errors.po file.
    # Ecto will pass the :count keyword if the error message is
    # meant to be pluralized.
    # On your own code and templates, depending on whether you
    # need the message to be pluralized or not, this could be
    # written simply as:
    #
    #     dngettext "errors", "1 file", "%{count} files", count
    #     dgettext "errors", "is invalid"
    #

    if count = opts[:count] do
      Gettext.dngettext(GettextBackend, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(GettextBackend, "errors", msg, opts)
    end
  end
end
