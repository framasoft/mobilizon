defmodule EventosWeb.AccountView do
  use EventosWeb, :view

  def render("account.json", %{"account": account}) do
    %{
      username: account.username,
      description: account.description,
      display_name: account.display_name,
      domain: account.domain,
      suspended: account.suspended,
      uri: account.uri,
      url: account.url,
    }
  end
end
