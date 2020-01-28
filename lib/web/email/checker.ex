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
end
