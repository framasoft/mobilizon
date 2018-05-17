defmodule Eventos.Service.XmlBuilder do
  def to_xml({tag, attributes, content}) do
    open_tag = make_open_tag(tag, attributes)

    content_xml = to_xml(content)

    "<#{open_tag}>#{content_xml}</#{tag}>"
  end

  def to_xml({tag, %{} = attributes}) do
    open_tag = make_open_tag(tag, attributes)

    "<#{open_tag} />"
  end

  def to_xml({tag, content}), do: to_xml({tag, %{}, content})

  def to_xml(content) when is_binary(content) do
    to_string(content)
  end

  def to_xml(content) when is_list(content) do
    for element <- content do
      to_xml(element)
    end
    |> Enum.join()
  end

  def to_xml(%NaiveDateTime{} = time) do
    NaiveDateTime.to_iso8601(time)
  end

  def to_doc(content), do: ~s(<?xml version="1.0" encoding="UTF-8"?>) <> to_xml(content)

  defp make_open_tag(tag, attributes) do
    attributes_string =
      for {attribute, value} <- attributes do
        "#{attribute}=\"#{value}\""
      end
      |> Enum.join(" ")

    [tag, attributes_string] |> Enum.join(" ") |> String.trim()
  end
end
