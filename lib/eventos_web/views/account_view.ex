defmodule EventosWeb.AccountView do
  use EventosWeb, :view
  alias EventosWeb.AccountView

  def render("index.json", %{accounts: accounts}) do
    %{data: render_many(accounts, AccountView, "account_for_user.json")}
  end

  def render("show.json", %{account: account}) do
    %{data: render_one(account, AccountView, "account.json")}
  end

  def render("account_for_user.json", %{account: account}) do
    %{id: account.id,
      username: account.username,
      domain: account.domain,
      display_name: account.display_name,
      description: account.description,
      public_key: account.public_key,
      suspended: account.suspended,
      uri: account.uri,
      url: account.url,
    }
  end

  def render("account.json", %{account: account}) do
    %{id: account.id,
      username: account.username,
      domain: account.domain,
      display_name: account.display_name,
      description: account.description,
      public_key: account.public_key,
      suspended: account.suspended,
      uri: account.uri,
      url: account.url,
      organized_events: account.organized_events
    }
  end
end
