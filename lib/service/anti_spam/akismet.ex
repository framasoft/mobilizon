defmodule Mobilizon.Service.AntiSpam.Akismet do
  @moduledoc """
  Validate user data
  """

  alias Exkismet.Comment, as: AkismetComment
  alias Mobilizon.{Actors, Discussions, Events, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Reports.Report
  alias Mobilizon.Service.AntiSpam.Provider
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Endpoint
  require Logger

  @behaviour Provider

  @env Application.compile_env(:mobilizon, :env)

  @impl Provider
  @spec check_user(String.t(), String.t(), String.t()) ::
          :ham | :spam | :discard | {:error, HTTPoison.Response.t()}
  def check_user(email, ip, user_agent) do
    check_content(%AkismetComment{
      blog: homepage(),
      user_ip: ip,
      comment_author_email: email,
      user_agent: user_agent,
      comment_type: "signup"
    })
  end

  @impl Provider
  @spec check_profile(String.t(), String.t(), String.t() | nil, String.t(), String.t()) ::
          :ham | :spam | :discard | {:error, HTTPoison.Response.t()}
  def check_profile(username, summary, email \\ nil, ip \\ "127.0.0.1", user_agent \\ nil) do
    check_content(%AkismetComment{
      blog: homepage(),
      user_ip: ip,
      comment_author: username,
      comment_author_email: email,
      comment_content: summary,
      user_agent: user_agent,
      comment_type: "signup"
    })
  end

  @impl Provider
  @spec check_event(String.t(), String.t(), String.t() | nil, String.t(), String.t()) ::
          :ham | :spam | :discard | {:error, HTTPoison.Response.t()}
  def check_event(event_body, username, email \\ nil, ip \\ "127.0.0.1", user_agent \\ nil) do
    check_content(%AkismetComment{
      blog: homepage(),
      user_ip: ip,
      comment_author: username,
      comment_author_email: email,
      comment_content: event_body,
      user_agent: user_agent,
      comment_type: "blog-post"
    })
  end

  @impl Provider
  @spec check_comment(String.t(), String.t(), boolean(), String.t() | nil, String.t(), String.t()) ::
          :ham | :spam | :discard | {:error, HTTPoison.Response.t()}
  def check_comment(
        comment_body,
        username,
        is_reply?,
        email \\ nil,
        ip \\ "127.0.0.1",
        user_agent \\ nil
      ) do
    check_content(%AkismetComment{
      blog: homepage(),
      user_ip: ip,
      comment_author: username,
      comment_author_email: email,
      comment_content: comment_body,
      user_agent: user_agent,
      comment_type: if(is_reply?, do: "reply", else: "comment")
    })
  end

  @spec report_ham(Report.t()) :: :ok | {:error, atom()} | {:error, HTTPoison.Response.t()}
  def report_ham(%Report{} = report) do
    report
    |> report_to_akismet_comment()
    |> submit_ham()
  end

  @spec report_spam(Report.t()) :: :ok | {:error, atom()} | {:error, HTTPoison.Response.t()}
  def report_spam(%Report{} = report) do
    report
    |> report_to_akismet_comment()
    |> submit_spam()
  end

  @spec homepage() :: String.t()
  defp homepage do
    Endpoint.url()
  end

  defp check_content(%AkismetComment{} = comment) do
    if @env != :test and ready?() do
      comment
      |> Exkismet.comment_check(key: api_key())
    else
      :ham
    end
  end

  defp api_key do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:key])
  end

  @impl Provider
  def ready?, do: !is_nil(api_key())

  @spec report_to_akismet_comment(Report.t()) :: AkismetComment.t() | {:error, atom()}
  defp report_to_akismet_comment(%Report{comments: [comment | _]}) do
    with %Comment{text: body, actor: %Actor{} = actor} <-
           Discussions.get_comment_with_preload(comment.id),
         {email, preferred_username, ip} <- actor_details(actor) do
      %AkismetComment{
        blog: homepage(),
        comment_content: body,
        comment_author_email: email,
        comment_author: preferred_username,
        user_ip: ip
      }
    else
      {:error, err} ->
        {:error, err}

      err ->
        {:error, err}
    end
  end

  defp report_to_akismet_comment(%Report{event: %Event{id: event_id}}) do
    with %Event{description: body, organizer_actor: %Actor{} = actor} <-
           Events.get_event_with_preload!(event_id),
         {email, preferred_username, ip} <- actor_details(actor) do
      %AkismetComment{
        blog: homepage(),
        comment_content: body,
        comment_author_email: email,
        comment_author: preferred_username,
        user_ip: ip
      }
    else
      {:error, err} ->
        {:error, err}

      err ->
        {:error, err}
    end
  end

  defp report_to_akismet_comment(%Report{reported_id: reported_id}) do
    case reported_id |> Actors.get_actor_with_preload!() |> actor_details() do
      {email, preferred_username, ip} ->
        %AkismetComment{
          blog: homepage(),
          comment_author_email: email,
          comment_author: preferred_username,
          user_ip: ip
        }

      {:error, err} ->
        {:error, err}

      err ->
        {:error, err}
    end
  end

  @spec actor_details(Actor.t()) :: {String.t(), String.t(), any()} | {:error, :invalid_actor}
  defp actor_details(%Actor{
         type: :Person,
         preferred_username: preferred_username,
         user: %User{
           current_sign_in_ip: current_sign_in_ip,
           last_sign_in_ip: last_sign_in_ip,
           email: email
         }
       }) do
    {email, preferred_username, current_sign_in_ip || last_sign_in_ip}
  end

  defp actor_details(%Actor{
         type: :Person,
         preferred_username: preferred_username,
         user_id: user_id
       })
       when not is_nil(user_id) do
    case user_id |> Users.get_user() |> user_details() do
      {email, ip} ->
        {preferred_username, email, ip}

      _ ->
        {:error, :invalid_actor}
    end
  end

  defp actor_details(%Actor{
         type: :Person,
         preferred_username: preferred_username,
         user_id: nil
       }) do
    {nil, preferred_username, "127.0.0.1"}
  end

  defp actor_details(_) do
    {:error, :invalid_actor}
  end

  @spec user_details(User.t()) :: {String.t(), any()} | {:error, :user_not_found}
  defp user_details(%User{
         current_sign_in_ip: current_sign_in_ip,
         last_sign_in_ip: last_sign_in_ip,
         email: email
       }) do
    {email, current_sign_in_ip || last_sign_in_ip}
  end

  defp user_details(_), do: {:error, :user_not_found}

  @spec submit_spam(AkismetComment.t() | :error) ::
          :ok | {:error, atom()} | {:error, HTTPoison.Response.t()}
  defp submit_spam(%AkismetComment{} = comment) do
    comment
    |> tap(fn comment ->
      Logger.info("Submitting content to Akismet as spam: #{inspect(comment)}")
    end)
    |> Exkismet.submit_spam(key: api_key())
    |> log_response()
  end

  defp submit_spam({:error, err}), do: {:error, err}

  @spec submit_ham(AkismetComment.t() | :error) ::
          :ok | {:error, atom()} | {:error, HTTPoison.Response.t()}
  defp submit_ham(%AkismetComment{} = comment) do
    comment
    |> tap(fn comment ->
      Logger.info("Submitting content to Akismet as ham: #{inspect(comment)}")
    end)
    |> Exkismet.submit_ham(key: api_key())
    |> log_response()
  end

  defp submit_ham({:error, err}), do: {:error, err}

  defp log_response(res),
    do: tap(res, fn res -> Logger.debug("Return from Akismet is: #{inspect(res)}") end)
end
