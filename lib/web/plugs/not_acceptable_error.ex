defimpl Plug.Exception, for: Phoenix.NotAcceptableError do
  def status(_exception), do: 406
  def actions(_exception), do: []
end
