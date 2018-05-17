defmodule EventosWeb.AccountView do
  @moduledoc """
  View for Accounts
  """
  use EventosWeb, :view
  alias EventosWeb.{AccountView, EventView}

  def render("index.json", %{accounts: accounts}) do
    %{data: render_many(accounts, AccountView, "acccount_basic.json")}
  end

  def render("show.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account.json")}
  end

  def render("show_basic.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account_basic.json")}
  end

  def render("acccount_basic.json", %{account: account}) do
    %{id: account.id,
      username: account.username,
      domain: account.domain,
      display_name: account.display_name,
      description: account.description,
      # public_key: account.public_key,
      suspended: account.suspended,
      url: account.url,
      avatar_url: account.avatar_url,
      banner_url: account.banner_url,
    }
  end

  def render("account.json", %{account: account}) do
    %{id: account.id,
      username: account.username,
      domain: account.domain,
      display_name: account.display_name,
      description: account.description,
      # public_key: account.public_key,
      suspended: account.suspended,
      url: account.url,
      avatar_url: account.avatar_url,
      banner_url: account.banner_url,
      organized_events: render_many(account.organized_events, EventView, "event_simple.json")
    }
  end
end
