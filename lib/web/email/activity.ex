defmodule Mobilizon.Web.Email.Activity do
  @moduledoc """
  Handles emails sent about activity notifications.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Web.{Email, Gettext}

  @spec direct_activity(String.t(), list(), String.t()) ::
          Bamboo.Email.t()
  def direct_activity(
        email,
        activities,
        options \\ []
      ) do
    locale = Keyword.get(options, :locale, "en")
    single_activity = Keyword.get(options, :single_activity, false)
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Activity notification for %{instance}",
        instance: Config.instance_name()
      )

    chunked_activities = chunk_activities(activities)

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:subject, subject)
    |> assign(:activities, chunked_activities)
    |> assign(:total_number_activities, length(activities))
    |> assign(:single_activity, single_activity)
    |> render(:email_direct_activity)
  end

  @spec chunk_activities(list()) :: map()
  defp chunk_activities(activities) do
    activities
    |> Enum.reduce(%{}, fn %Activity{group: %Actor{id: group_id}} = activity, acc ->
      Map.update(acc, group_id, [activity], fn activities -> activities ++ [activity] end)
    end)
    |> Enum.map(fn {key, value} ->
      {key, Enum.sort(value, &(&1.inserted_at <= &2.inserted_at))}
    end)
    |> Enum.map(fn {key, value} -> {key, filter_duplicates(value)} end)
    |> Enum.into(%{})
  end

  # We filter duplicates when subject_params are being the same
  # so it will probably not catch much things
  @spec filter_duplicates(list()) :: list()
  defp filter_duplicates(activities) do
    Enum.uniq_by(activities, fn %Activity{
                                  author: %Actor{id: author_id},
                                  group: %Actor{id: group_id},
                                  type: type,
                                  subject: subject,
                                  subject_params: subject_params
                                } ->
      %{
        author_id: author_id,
        group_id: group_id,
        type: type,
        subject: subject,
        subject_params: subject_params
      }
    end)
  end
end
