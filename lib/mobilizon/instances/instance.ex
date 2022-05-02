defmodule Mobilizon.Instances.Instance do
  @moduledoc """
  An instance representation

  Using a MATERIALIZED VIEW underneath
  """
  use Ecto.Schema

  @type t :: %__MODULE__{
          domain: String.t(),
          event_count: non_neg_integer(),
          person_count: non_neg_integer(),
          group_count: non_neg_integer(),
          followers_count: non_neg_integer(),
          followings_count: non_neg_integer(),
          reports_count: non_neg_integer(),
          media_size: non_neg_integer()
        }

  @primary_key {:domain, :string, []}
  schema "instances" do
    field(:event_count, :integer)
    field(:person_count, :integer)
    field(:group_count, :integer)
    field(:followers_count, :integer)
    field(:followings_count, :integer)
    field(:reports_count, :integer)
    field(:media_size, :integer)
  end
end
