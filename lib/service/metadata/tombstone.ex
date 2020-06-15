defimpl Mobilizon.Service.Metadata, for: Mobilizon.Tombstone do
  alias Mobilizon.Tombstone

  def build_tags(%Tombstone{}, _locale \\ "en") do
    []
  end
end
