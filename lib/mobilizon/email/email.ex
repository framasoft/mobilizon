defmodule Mobilizon.Email do
  @moduledoc """
  The Email context.
  """

  use Bamboo.Phoenix, view: Mobilizon.EmailView

  alias Mobilizon.Config

  @spec base_email :: Bamboo.Email.t()
  def base_email do
    new_email()
    |> from(Config.instance_email_from())
    |> put_html_layout({Mobilizon.EmailView, "email.html"})
    |> put_text_layout({Mobilizon.EmailView, "email.text"})
  end
end
