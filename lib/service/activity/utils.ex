defmodule Mobilizon.Service.Activity.Utils do
  @moduledoc """
  Utils for activities
  """

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Service.Activity, as: ActivityService

  def transform_activity(%Activity{} = activity) do
    activity
    |> Map.update(:subject_params, %{}, &transform_params/1)
    |> add_activity_object()
  end

  @spec add_activity_object(Activity.t()) :: Activity.t()
  def add_activity_object(%Activity{} = activity) do
    %Activity{activity | object: ActivityService.object(activity)}
  end

  @spec transform_params(map()) :: list()
  defp transform_params(params) do
    Enum.map(params, fn {key, value} -> %{key: key, value: transform_value(value)} end)
  end

  defp transform_value(value) when is_list(value) do
    Enum.join(value, ",")
  end

  defp transform_value(value), do: value

  @spec maybe_inserted_at :: map()
  def maybe_inserted_at do
    if Application.fetch_env!(:mobilizon, :env) == :test do
      %{}
    else
      %{"inserted_at" => DateTime.utc_now()}
    end
  end
end
