defmodule Mobilizon.Events.Participant.Metadata do
  @moduledoc """
  Participation stats on event
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Web.Email.Checker

  @type t :: %__MODULE__{
          email: String.t(),
          confirmation_token: String.t(),
          cancellation_token: String.t(),
          message: String.t(),
          locale: String.t()
        }

  @attrs [:email, :confirmation_token, :cancellation_token, :message, :locale]

  @derive Jason.Encoder
  embedded_schema do
    field(:email, :string)
    field(:confirmation_token, :string)
    field(:cancellation_token, :string)
    field(:message, :string)
    field(:locale, :string)
  end

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, @attrs)
    |> Checker.validate_changeset()
  end
end
