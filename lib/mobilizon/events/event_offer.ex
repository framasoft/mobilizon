defmodule Mobilizon.Events.EventOffer do
  @moduledoc """
  Represents an event offer.
  """

  use Ecto.Schema

  @type t :: %__MODULE__{
          price: float,
          price_currency: String.t(),
          url: String.t()
        }

  embedded_schema do
    field(:price, :float)
    field(:price_currency, :string)
    field(:url, :string)
  end
end
