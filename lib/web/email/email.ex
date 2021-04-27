defmodule Mobilizon.Web.Email do
  @moduledoc """
  The Email context.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  alias Mobilizon.{Config, Events}
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.Export.ICalendar
  alias Mobilizon.Web.EmailView

  @spec base_email(keyword()) :: Bamboo.Email.t()
  def base_email(args) do
    instance = Config.instance_config()

    args
    |> new_email()
    |> from({Config.instance_name(), Config.instance_email_from()})
    |> put_header("Reply-To", Config.instance_email_reply_to())
    |> maybe_put_date_header()
    |> maybe_put_message_id()
    |> assign(:instance, instance)
    |> put_html_layout({EmailView, "email.html"})
    |> put_text_layout({EmailView, "email.text"})
  end

  # Generating an UUID randomly causes Bamboo.Test.assert_delivered_email/1 to fail
  defp maybe_put_message_id(email) do
    if Application.fetch_env!(:mobilizon, :env) == :test do
      put_header(email, "Message-Id", "TEST_ENV_MESSAGE_ID@#{Config.instance_hostname()}")
    else
      email
    end
  end

  defp maybe_put_date_header(email) do
    if Application.fetch_env!(:mobilizon, :env) == :test do
      put_header(email, "Date", "REMOVED FOR TESTING")
    else
      email
    end
  end

  def add_event_attachment(%Bamboo.Email{} = email, %Event{id: event_id}) do
    with {:ok, %Event{} = event} <- Events.get_event_with_preload(event_id),
         {:ok, event_ics_data} <- ICalendar.export_event(event) do
      put_attachment(email, %Bamboo.Attachment{
        filename: Slugger.slugify_downcase(event.title),
        content_type: "text/calendar",
        data: event_ics_data
      })
    else
      _ ->
        email
    end
  end
end
