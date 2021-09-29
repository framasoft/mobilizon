defmodule Mobilizon.Service.LanguageDetection do
  @moduledoc """
  Detect the language of the event
  """
  alias Mobilizon.Service.Formatter.HTML

  @und "und"

  @paasaa_languages Paasaa.Data.languages()
                    |> Map.values()
                    |> List.flatten()
                    |> Enum.map(fn {lang, _val} ->
                      lang
                    end)

  @allow_listed_locales Mobilizon.Cldr.known_locale_names()

  @type entity_type :: :event | :comment | :post

  @spec detect(entity_type(), map()) :: String.t()
  def detect(:event, %{title: title} = args) do
    description = Map.get(args, :description)

    if is_nil(description) or description == "" do
      title
      |> Paasaa.detect(whitelist: allow_listed_languages())
      |> normalize()
    else
      sanitized_description = HTML.strip_tags_and_insert_spaces(description)

      "#{title}\n\n#{sanitized_description}"
      |> Paasaa.detect(whitelist: allow_listed_languages())
      |> normalize()
    end
  end

  def detect(:comment, %{text: text}) do
    text
    |> HTML.strip_tags_and_insert_spaces()
    |> Paasaa.detect(whitelist: allow_listed_languages())
    |> normalize()
  end

  def detect(:post, %{title: title} = args) do
    body = Map.get(args, :body)

    if is_nil(body) or body == "" do
      title
      |> Paasaa.detect(whitelist: allow_listed_languages())
      |> normalize()
    else
      sanitized_body = HTML.strip_tags_and_insert_spaces(body)

      "#{title}\n\n#{sanitized_body}"
      |> Paasaa.detect(whitelist: allow_listed_languages())
      |> normalize()
    end
  end

  def detect(_, _), do: @und

  @spec normalize(String.t()) :: String.t()
  def normalize(""), do: @und

  def normalize(language) do
    case Cldr.AcceptLanguage.parse(language, Mobilizon.Cldr) do
      {:ok, [{_, %Cldr.LanguageTag{} = tag}]} ->
        tag.language

      _ ->
        @und
    end
  end

  def allow_listed_languages do
    @paasaa_languages
    |> Enum.map(fn lang ->
      {__MODULE__.normalize(lang), lang}
    end)
    |> Enum.into(%{})
    |> Map.take(@allow_listed_locales)
    |> Map.values()
  end
end
