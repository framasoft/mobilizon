defmodule Mobilizon.Instances.Instance do
  @moduledoc """
  An instance representation

  Using a MATERIALIZED VIEW underneath
  """
  use Ecto.Schema

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
