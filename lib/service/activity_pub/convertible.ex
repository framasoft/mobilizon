defprotocol Mobilizon.Service.ActivityPub.Convertible do
  @moduledoc """
  Convertible protocol.
  """

  @type activity_streams :: map

  @spec model_to_as(t) :: activity_streams
  def model_to_as(convertible)
end
