defmodule Mobilizon.Web.Email do
  @moduledoc """
  The Email context.
  """

  use Phoenix.Swoosh, view: Mobilizon.Web.EmailView, layout: {Mobilizon.Web.EmailView, :email}

  alias Mobilizon.{Config, Events}
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.ICalendar
  alias Mobilizon.Web.EmailView

  @spec base_email(keyword()) :: Swoosh.Email.t()
  def base_email(args) do
    [reply_to: Config.instance_email_reply_to() || Config.instance_email_from()]
    |> Keyword.merge(args)
    |> new()
    |> from({Config.instance_name(), Config.instance_email_from()})
    |> assign(:jsonLDMetadata, nil)
    |> assign(:instance_name, Config.instance_name())
    |> assign(:offer_unsupscription, true)
    |> put_layout({EmailView, :email})
  end

  @spec add_event_attachment(Swoosh.Email.t(), Event.t()) :: Swoosh.Email.t()
  def add_event_attachment(%Swoosh.Email{} = email, %Event{id: event_id}) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:ok, event_ics_data} <- ICalendar.export_event(event) do
      attachment(email, %Swoosh.Attachment{
        filename: "#{Slugger.slugify_downcase(event.title)}.ics",
        content_type: "text/calendar",
        data: event_ics_data
      })
    else
      _ ->
        email
    end
  end
end
