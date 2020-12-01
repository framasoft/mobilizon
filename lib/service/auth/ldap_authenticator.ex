# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.Auth.LDAPAuthenticator do
  @moduledoc """
  Authenticate Mobilizon users through LDAP accounts
  """
  alias Mobilizon.Service.Auth.{Authenticator, MobilizonAuthenticator}
  alias Mobilizon.Users
  alias Mobilizon.Users.User

  require Logger

  import Authenticator,
    only: [fetch_user: 1]

  @behaviour Authenticator
  @base MobilizonAuthenticator

  @connection_timeout 10_000
  @search_timeout 10_000

  def login(email, password) do
    with {:ldap, true} <- {:ldap, Mobilizon.Config.get([:ldap, :enabled])},
         %User{} = user <- ldap_user(email, password) do
      {:ok, user}
    else
      {:error, {:ldap_connection_error, _}} ->
        # When LDAP is unavailable, try default authenticator
        @base.login(email, password)

      {:ldap, _} ->
        @base.login(email, password)

      error ->
        error
    end
  end

  def can_change_email?(%User{provider: provider}), do: provider != "ldap"

  def can_change_password?(%User{provider: provider}), do: provider != "ldap"

  defp ldap_user(email, password) do
    ldap = Mobilizon.Config.get(:ldap, [])
    host = Keyword.get(ldap, :host, "localhost")
    port = Keyword.get(ldap, :port, 389)
    ssl = Keyword.get(ldap, :ssl, false)
    sslopts = Keyword.get(ldap, :sslopts, [])

    options =
      [{:port, port}, {:ssl, ssl}, {:timeout, @connection_timeout}] ++
        if sslopts != [], do: [{:sslopts, sslopts}], else: []

    case :eldap.open([to_charlist(host)], options) do
      {:ok, connection} ->
        try do
          ensure_eventual_tls(connection, ldap)

          base = Keyword.get(ldap, :base)
          uid_field = Keyword.get(ldap, :uid, "cn")
          group = Keyword.get(ldap, :group, false)

          # We first need to find the LDAP UID/CN for this specif email
          with uid when is_binary(uid) <-
                 search_user(connection, ldap, base, uid_field, email, group),
               # Then we can verify the user's password
               :ok <- bind_user(connection, base, uid_field, uid, password) do
            case fetch_user(email) do
              %User{disabled: false} = user ->
                user

              %User{disabled: true} = _user ->
                {:error, :disabled_user}

              _ ->
                register_user(email)
            end
          else
            {:error, err}
            when err in [:ldap_search_email_not_found, :ldap_search_missing_attributes] ->
              {:ldap, err}

            {:error, error} ->
              {:error, error}

            error ->
              {:error, error}
          end
        after
          :eldap.close(connection)
        end

      {:error, error} ->
        Logger.error("Could not open LDAP connection: #{inspect(error)}")
        {:error, {:ldap_connection_error, error}}
    end
  end

  # Bind user with full DN
  @spec bind_user(any(), String.t(), String.t(), {:full, String.t()}, String.t()) ::
          User.t() | any()
  defp bind_user(connection, _base, _uid, {:full, field}, password) do
    Logger.debug("Binding to LDAP with \"#{field}\"")
    :eldap.simple_bind(connection, field, password)
  end

  # Bind user with only uid field on top of base
  @spec bind_user(any(), String.t(), String.t(), String.t(), String.t()) ::
          User.t() | any()
  defp bind_user(connection, base, uid, field, password) do
    bind = "#{uid}=#{field},#{base}"
    Logger.debug("Binding to LDAP with \"#{bind}\"")
    :eldap.simple_bind(connection, bind, password)
  end

  @spec search_user(
          any(),
          Keyword.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t() | boolean()
        ) ::
          String.t() | {:error, :ldap_registration_missing_attributes} | any()
  defp search_user(connection, ldap, base, uid, email, group) do
    # We may need to bind before performing the search
    res =
      if Keyword.get(ldap, :require_bind_for_search, true) do
        admin_field = Keyword.get(ldap, :bind_uid)
        admin_password = Keyword.get(ldap, :bind_password)
        bind_user(connection, base, uid, admin_field, admin_password)
      else
        :ok
      end

    if res == :ok do
      do_search_user(connection, base, uid, email, group)
    else
      res
    end
  end

  # Search an user by uid to find their CN
  @spec do_search_user(any(), String.t(), String.t(), String.t(), String.t() | boolean()) ::
          String.t() | {:error, :ldap_registration_missing_attributes} | any()
  defp do_search_user(connection, base, uid, email, group) do
    with {:ok, {:eldap_search_result, [{:eldap_entry, _, attributes}], _}} <-
           :eldap.search(connection, [
             {:base, to_charlist(base)},
             {:filter, search_filter(email, group)},
             {:scope, :eldap.wholeSubtree()},
             {:attributes, [to_charlist(uid)]},
             {:timeout, @search_timeout}
           ]),
         {:uid, {_, [uid]}} <- {:uid, List.keyfind(attributes, to_charlist(uid), 0)} do
      :erlang.list_to_binary(uid)
    else
      {:ok, {:eldap_search_result, [], []}} ->
        Logger.info("Unable to find user with email #{email}")
        {:error, :ldap_search_email_not_found}

      {:cn, err} ->
        Logger.error("Could not find LDAP attribute CN: #{inspect(err)}")
        {:error, :ldap_search_missing_attributes}

      error ->
        error
    end
  end

  @spec search_filter(String.t(), boolean()) :: any()
  defp search_filter(email, false) do
    :eldap.equalityMatch('mail', to_charlist(email))
  end

  # If we need to filter for group memberships as well
  @spec search_filter(String.t(), String.t()) :: any()
  defp search_filter(email, group) when is_binary(group) do
    :eldap.and([
      :eldap.equalityMatch('mail', to_charlist(email)),
      :eldap.equalityMatch('memberOf', to_charlist(group))
    ])
  end

  @spec register_user(String.t()) :: User.t() | any()
  defp register_user(email) do
    case Users.create_external(email, "ldap") do
      {:ok, %User{} = user} ->
        user

      error ->
        error
    end
  end

  @spec ensure_eventual_tls(any(), Keyword.t()) :: :ok
  defp ensure_eventual_tls(connection, ldap) do
    if Keyword.get(ldap, :tls, false) do
      :application.ensure_all_started(:ssl)

      case :eldap.start_tls(
             connection,
             Keyword.get(ldap, :tlsopts, []),
             @connection_timeout
           ) do
        :ok ->
          :ok

        error ->
          Logger.error("Could not start TLS: #{inspect(error)}")
      end
    end

    :ok
  end
end
