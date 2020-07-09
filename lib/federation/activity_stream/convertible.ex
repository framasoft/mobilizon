defprotocol Mobilizon.Federation.ActivityStream.Convertible do
  @moduledoc """
  Convertible protocol.
  """

  @type t :: struct()
  @type activity_streams :: map()

  @spec model_to_as(t()) :: activity_streams()
  def model_to_as(convertible)
end
