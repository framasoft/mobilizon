defmodule Mobilizon.Web.Email.Checker do
  @moduledoc """
  Provides a function to test emails against a "not so bad" regex.
  """

  @email_regex ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$/i

  @doc """
  Returns whether the email is valid.
  """
  @spec valid?(String.t()) :: boolean
  def valid?(email), do: email =~ @email_regex

  @spec validate_changeset(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_changeset(%Ecto.Changeset{} = changeset, key \\ :email) do
    changeset = Ecto.Changeset.validate_length(changeset, :email, min: 3, max: 250)

    case Ecto.Changeset.fetch_change(changeset, key) do
      {:ok, email} ->
        if valid?(email),
          do: changeset,
          else: Ecto.Changeset.add_error(changeset, :email, "Email doesn't fit required format")

      :error ->
        changeset
    end
  end
end
