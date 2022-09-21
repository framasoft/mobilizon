defmodule Mobilizon.Service.UnplugPredicates.AppConfigKeywordEquals do
  @moduledoc """
  Given an application and a key, execute the plug if the configured value
  matches the expected value.
  Usage:
  ```elixir
  plug Unplug,
    if: {Unplug.Predicates.AppConfigEquals, {:my_app, :some_config, :enabled}},
    do: MyApp.Plug
  ```
  """

  @behaviour Unplug.Predicate

  @impl true
  def call(_conn, {app, key, keyword_key, keyword_default_value, expected_value}) do
    app |> Application.get_env(key) |> Keyword.get(keyword_key, keyword_default_value) ==
      expected_value
  end
end
