# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/reverse_proxy.ex

defmodule Mobilizon.Web.ReverseProxy do
  @range_headers ~w(range if-range)
  @keep_req_headers ~w(accept user-agent accept-encoding cache-control if-modified-since) ++
                      ~w(if-unmodified-since if-none-match) ++ @range_headers
  @resp_cache_headers ~w(etag date last-modified)
  @keep_resp_headers @resp_cache_headers ++
                       ~w(content-length content-type content-disposition content-encoding) ++
                       ~w(content-range accept-ranges vary)
  @default_cache_control_header "public, max-age=1209600"
  @valid_resp_codes [200, 206, 304]
  @max_read_duration :timer.seconds(30)
  @max_body_length :infinity
  @methods ~w(GET HEAD)

  def max_read_duration_default, do: @max_read_duration
  def default_cache_control_header, do: @default_cache_control_header

  @moduledoc """
  A reverse proxy.

      Mobilizon.Web.ReverseProxy.call(conn, url, options)

  It is not meant to be added into a plug pipeline, but to be called from another
  plug or controller.

  Supports `#{inspect(@methods)}` HTTP methods, and only allows
  `#{inspect(@valid_resp_codes)}` status codes.

  Responses are chunked to the client while downloading from the upstream.

  Some request / responses headers are preserved:

    * request: `#{inspect(@keep_req_headers)}`
    * response: `#{inspect(@keep_resp_headers)}`

  If no caching headers (`#{inspect(@resp_cache_headers)}`) are returned by
  upstream, `cache-control` will be set to `#{inspect(@default_cache_control_header)}`.

  Options:

    * `redirect_on_failure` (default `false`). Redirects the client to the real
    remote URL if there's any HTTP errors. Any error during body processing will
    not be redirected as the response is chunked. This may expose remote URL,
    clients IPs, ….

    * `max_body_length` (default `#{inspect(@max_body_length)}`): limits the
    content length to be approximately the specified length. It is validated with
    the `content-length` header and also verified when proxying.

    * `max_read_duration` (default `#{inspect(@max_read_duration)}` ms): the total
    time the connection is allowed to read from the remote upstream.

    * `inline_content_types`:
      * `true` will not alter `content-disposition` (up to the upstream),
      * `false` will add `content-disposition: attachment` to any request,
      * a list of allowlisted content types

      * `keep_user_agent` will forward the client's user-agent to the upstream.
      This may be useful if the upstream is doing content transformation
      (encoding, …) depending on the request.

    * `req_headers`, `resp_headers` additional headers.

    * `http`: options for [hackney](https://github.com/benoitc/hackney).

  """

  import Plug.Conn

  alias Plug.Conn

  require Logger

  @type option ::
          {:keep_user_agent, boolean}
          | {:max_read_duration, :timer.time() | :infinity}
          | {:max_body_length, non_neg_integer | :infinity}
          | {:http, []}
          | {:req_headers, [{String.t(), String.t()}]}
          | {:resp_headers, [{String.t(), String.t()}]}
          | {:inline_content_types, boolean | [String.t()]}
          | {:redirect_on_failure, boolean}

  @hackney Application.get_env(:mobilizon, :hackney, :hackney)

  @default_hackney_options []

  @inline_content_types [
    "image/gif",
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/svg+xml",
    "audio/mpeg",
    "audio/mp3",
    "video/webm",
    "video/mp4",
    "video/quicktime"
  ]

  @spec call(Plug.Conn.t(), url :: String.t(), [option]) :: Plug.Conn.t()
  def call(_conn, _url, _opts \\ [])

  def call(conn = %{method: method}, url, opts) when method in @methods do
    hackney_opts =
      @default_hackney_options
      |> Keyword.merge(Keyword.get(opts, :http, []))

    req_headers = build_req_headers(conn.req_headers, opts)

    opts =
      if filename = filename(url) do
        Keyword.put_new(opts, :attachment_name, filename)
      else
        opts
      end

    with {:ok, code, headers, client} <- request(method, url, req_headers, hackney_opts),
         :ok <- header_length_constraint(headers, Keyword.get(opts, :max_body_length)) do
      response(conn, client, url, code, headers, opts)
    else
      {:ok, code, headers} ->
        conn
        |> head_response(url, code, headers, opts)
        |> halt()

      {:error, {:invalid_http_response, code}} ->
        Logger.error("#{__MODULE__}: request to #{inspect(url)} failed with HTTP status #{code}")

        conn
        |> error_or_redirect(
          url,
          code,
          "Request failed: " <> Conn.Status.reason_phrase(code),
          opts
        )
        |> halt()

      {:error, error} ->
        Logger.error("#{__MODULE__}: request to #{inspect(url)} failed: #{inspect(error)}")

        conn
        |> error_or_redirect(url, 500, "Request failed", opts)
        |> halt()
    end
  end

  # sobelow_skip ["XSS.SendResp"]
  def call(conn, _, _) do
    conn
    |> send_resp(400, Conn.Status.reason_phrase(400))
    |> halt()
  end

  defp request(method, url, headers, hackney_opts) do
    Logger.debug("#{__MODULE__} #{method} #{url} #{inspect(headers)}")
    method = method |> String.downcase() |> String.to_existing_atom()

    case @hackney.request(method, url, headers, "", hackney_opts) do
      {:ok, code, headers, client} when code in @valid_resp_codes ->
        {:ok, code, downcase_headers(headers), client}

      {:ok, code, headers} when code in @valid_resp_codes ->
        {:ok, code, downcase_headers(headers)}

      {:ok, code, _, _} ->
        {:error, {:invalid_http_response, code}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp response(conn, client, url, status, headers, opts) do
    result =
      conn
      |> put_resp_headers(build_resp_headers(headers, opts))
      |> send_chunked(status)
      |> chunk_reply(client, opts)

    case result do
      {:ok, conn} ->
        halt(conn)

      {:error, :closed, conn} ->
        :hackney.close(client)
        halt(conn)

      {:error, error, conn} ->
        Logger.warn(
          "#{__MODULE__} request to #{url} failed while reading/chunking: #{inspect(error)}"
        )

        :hackney.close(client)
        halt(conn)
    end
  end

  defp chunk_reply(conn, client, opts) do
    chunk_reply(conn, client, opts, 0, 0)
  end

  defp chunk_reply(conn, client, opts, sent_so_far, duration) do
    with {:ok, duration} <-
           check_read_duration(
             duration,
             Keyword.get(opts, :max_read_duration, @max_read_duration)
           ),
         {:ok, data} <- @hackney.stream_body(client),
         {:ok, duration} <- increase_read_duration(duration),
         sent_so_far = sent_so_far + byte_size(data),
         :ok <- body_size_constraint(sent_so_far, Keyword.get(opts, :max_body_size)),
         {:ok, conn} <- chunk(conn, data) do
      chunk_reply(conn, client, opts, sent_so_far, duration)
    else
      :done -> {:ok, conn}
      {:error, error} -> {:error, error, conn}
    end
  end

  defp head_response(conn, _url, code, headers, opts) do
    conn
    |> put_resp_headers(build_resp_headers(headers, opts))
    |> send_resp(code, "")
  end

  # sobelow_skip ["XSS.SendResp"]
  defp error_or_redirect(conn, url, code, body, opts) do
    if Keyword.get(opts, :redirect_on_failure, false) do
      conn
      |> Phoenix.Controller.redirect(external: url)
      |> halt()
    else
      conn
      |> send_resp(code, body)
      |> halt
    end
  end

  defp downcase_headers(headers) do
    Enum.map(headers, fn {k, v} ->
      {String.downcase(k), v}
    end)
  end

  defp get_content_type(headers) do
    {_, content_type} =
      List.keyfind(headers, "content-type", 0, {"content-type", "application/octet-stream"})

    [content_type | _] = String.split(content_type, ";")
    content_type
  end

  defp put_resp_headers(conn, headers) do
    Enum.reduce(headers, conn, fn {k, v}, conn ->
      put_resp_header(conn, k, v)
    end)
  end

  defp build_req_headers(headers, opts) do
    headers
    |> downcase_headers()
    |> Enum.filter(fn {k, _} -> k in @keep_req_headers end)
    |> (fn headers ->
          headers = headers ++ Keyword.get(opts, :req_headers, [])

          if Keyword.get(opts, :keep_user_agent, false) do
            List.keystore(
              headers,
              "user-agent",
              0,
              {"user-agent", Mobilizon.user_agent()}
            )
          else
            headers
          end
        end).()
  end

  defp build_resp_headers(headers, opts) do
    headers
    |> Enum.filter(fn {k, _} -> k in @keep_resp_headers end)
    |> build_resp_cache_headers(opts)
    |> build_resp_content_disposition_header(opts)
    |> (fn headers -> headers ++ Keyword.get(opts, :resp_headers, []) end).()
  end

  defp build_resp_cache_headers(headers, _opts) do
    has_cache? = Enum.any?(headers, fn {k, _} -> k in @resp_cache_headers end)
    has_cache_control? = List.keymember?(headers, "cache-control", 0)

    cond do
      has_cache? && has_cache_control? ->
        headers

      has_cache? ->
        # There's caching header present but no cache-control -- we need to explicitely override it
        # to public as Plug defaults to "max-age=0, private, must-revalidate"
        List.keystore(headers, "cache-control", 0, {"cache-control", "public"})

      true ->
        List.keystore(
          headers,
          "cache-control",
          0,
          {"cache-control", @default_cache_control_header}
        )
    end
  end

  defp build_resp_content_disposition_header(headers, opts) do
    opt = Keyword.get(opts, :inline_content_types, @inline_content_types)

    content_type = get_content_type(headers)

    attachment? =
      cond do
        is_list(opt) && !Enum.member?(opt, content_type) -> true
        opt == false -> true
        true -> false
      end

    if attachment? do
      name =
        try do
          {{"content-disposition", content_disposition_string}, _} =
            List.keytake(headers, "content-disposition", 0)

          [name | _] =
            Regex.run(
              ~r/filename="((?:[^"\\]|\\.)*)"/u,
              content_disposition_string || "",
              capture: :all_but_first
            )

          name
        rescue
          MatchError -> Keyword.get(opts, :attachment_name, "attachment")
        end

      disposition = "attachment; filename=\"#{name}\""

      List.keystore(headers, "content-disposition", 0, {"content-disposition", disposition})
    else
      headers
    end
  end

  defp header_length_constraint(headers, limit) when is_integer(limit) and limit > 0 do
    with {_, size} <- List.keyfind(headers, "content-length", 0),
         {size, _} <- Integer.parse(size),
         true <- size <= limit do
      :ok
    else
      false ->
        {:error, :body_too_large}

      _ ->
        :ok
    end
  end

  defp header_length_constraint(_, _), do: :ok

  defp body_size_constraint(size, limit) when is_integer(limit) and limit > 0 and size >= limit do
    {:error, :body_too_large}
  end

  defp body_size_constraint(_, _), do: :ok

  defp check_read_duration(duration, max)
       when is_integer(duration) and is_integer(max) and max > 0 do
    if duration > max do
      {:error, :read_duration_exceeded}
    else
      {:ok, {duration, :erlang.system_time(:millisecond)}}
    end
  end

  defp check_read_duration(_, _), do: {:ok, :no_duration_limit, :no_duration_limit}

  defp increase_read_duration({previous_duration, started})
       when is_integer(previous_duration) and is_integer(started) do
    duration = :erlang.system_time(:millisecond) - started
    {:ok, previous_duration + duration}
  end

  defp increase_read_duration(_) do
    {:ok, :no_duration_limit, :no_duration_limit}
  end

  def filename(url_or_path) do
    if path = URI.parse(url_or_path).path, do: Path.basename(path)
  end
end
