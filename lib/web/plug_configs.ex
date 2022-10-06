defmodule Mobilizon.Web.PlugConfigs do
  @moduledoc """
  Runtime configuration for plugs
  """

  def parsers do
    upload_limit =
      Keyword.get(Application.get_env(:mobilizon, :instance, []), :upload_limit, 10_485_760)

    [
      parsers: [:urlencoded, {:multipart, length: upload_limit}, :json, Absinthe.Plug.Parser]
    ]
  end
end
