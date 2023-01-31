defmodule Mix.Tasks.Mobilizon.Maintenance.DetectSpam do
  @moduledoc """
  Task to scan all profiles and events against spam detector and report them
  """
  use Mix.Task
  alias Mobilizon.{Actors, Config, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Akismet
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  @shortdoc "Scan all profiles and events against spam detector and report them"

  @impl Mix.Task
  def run(options) do
    {options, [], []} =
      OptionParser.parse(
        options,
        strict: [
          dry_run: :boolean,
          verbose: :boolean,
          forward_reports: :boolean,
          local_only: :boolean
        ],
        aliases: [
          d: :dry_run,
          v: :verbose,
          f: :forward_reports,
          l: :local_only
        ]
      )

    start_mobilizon()

    unless Akismet.ready?() do
      shell_error("Akismet is missing an API key in the configuration")
    end

    anonymous_actor_id = Config.anonymous_actor_id()

    options
    |> Keyword.get(:local_only, false)
    |> profiles()
    |> Stream.flat_map(& &1)
    |> Stream.each(fn profile ->
      process_profile(profile, Keyword.put(options, :anonymous_actor_id, anonymous_actor_id))
    end)
    |> Stream.run()

    options
    |> Keyword.get(:local_only, false)
    |> events()
    |> Stream.flat_map(& &1)
    |> Stream.each(fn event ->
      process_event(event, Keyword.put(options, :anonymous_actor_id, anonymous_actor_id))
    end)
    |> Stream.run()
  end

  defp profiles(local_only) do
    shell_info("Starting scanning of profiles")

    Actors.stream_persons("", "", "", local_only || nil, false)
  end

  defp events(local_only) do
    shell_info("Starting scanning of events")

    Events.stream_events(local_only || nil)
  end

  defp process_profile(
         %Actor{preferred_username: preferred_username, summary: summary, user: user, id: id},
         options
       ) do
    email = if(is_nil(user), do: nil, else: user.email)
    ip = if(is_nil(user), do: nil, else: user.current_sign_in_ip || user.last_sign_in_ip)

    case Akismet.check_profile(preferred_username, summary, email, ip) do
      res when res in [:spam, :discard] ->
        handle_spam_profile(preferred_username, id, options)

      :ham ->
        if verbose?(options) do
          shell_info("Profile #{preferred_username} is fine")
        end

      err ->
        shell_error(inspect(err))
    end
  end

  defp process_event(
         %Event{
           description: event_description,
           organizer_actor: organizer_actor,
           id: event_id,
           title: title,
           uuid: uuid
         },
         options
       ) do
    {email, ip} =
      if organizer_actor.user_id do
        user = Users.get_user(organizer_actor.user_id)
        email = if(is_nil(user), do: nil, else: user.email)
        ip = if(is_nil(user), do: nil, else: user.current_sign_in_ip || user.last_sign_in_ip)
        {email, ip}
      else
        {nil, nil}
      end

    case Akismet.check_event(event_description, organizer_actor.preferred_username, email, ip) do
      res when res in [:spam, :discard] ->
        handle_spam_event(event_id, title, uuid, organizer_actor.id, options)

      :ham ->
        if verbose?(options) do
          shell_info("Event #{title} is fine")
        end

      err ->
        shell_error(inspect(err))
    end
  end

  defp handle_spam_profile(preferred_username, organizer_actor_id, options) do
    shell_info("Detected profile #{preferred_username} as spam")

    unless dry_run?(options) do
      report_spam_profile(preferred_username, organizer_actor_id, options)
    end
  end

  defp report_spam_profile(profile_preferred_username, organizer_actor_id, options) do
    shell_info("Reporting profile #{profile_preferred_username} as spam")

    Actions.Flag.flag(
      %{
        reported_id: organizer_actor_id,
        reporter_id: Keyword.fetch!(options, :anonymous_actor_id),
        content: "This is an automatic report issued by Akismet"
      },
      Keyword.get(options, :forward_reports, false)
    )
  end

  defp handle_spam_event(event_id, event_title, event_uuid, organizer_actor_id, options) do
    shell_info(
      "Detected event #{event_title} as spam: #{Routes.page_url(Endpoint, :event, event_uuid)}"
    )

    unless dry_run?(options) do
      report_spam_event(event_id, event_title, organizer_actor_id, options)
    end
  end

  defp report_spam_event(event_id, event_title, organizer_actor_id, options) do
    shell_info("Reporting event #{event_title} as spam")

    Actions.Flag.flag(
      %{
        reported_id: organizer_actor_id,
        reporter_id: Keyword.fetch!(options, :anonymous_actor_id),
        event_id: event_id,
        content: "This is an automatic report issued by Akismet"
      },
      Keyword.get(options, :forward_reports, false)
    )
  end

  defp verbose?(options), do: Keyword.get(options, :verbose, false)
  defp dry_run?(options), do: Keyword.get(options, :dry_run, false)
end
