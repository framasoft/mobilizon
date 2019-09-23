defmodule MobilizonWeb.Email do
  @moduledoc """
  The Email context.
  """

  use Bamboo.Phoenix, view: MobilizonWeb.EmailView

  alias Mobilizon.Config

  @spec base_email(keyword()) :: Bamboo.Email.t()
  def base_email(args) do
    instance = Config.instance_config()

    new_email(args)
    |> from(Config.instance_email_from())
    |> put_header("Reply-To", Config.instance_email_reply_to())
    |> assign(:instance, instance)
    |> put_html_layout({MobilizonWeb.EmailView, "email.html"})
    |> put_text_layout(false)
  end

  def premail(email) do
    html = Premailex.to_inline_css(email.html_body)
    text = Premailex.to_text(email.html_body)

    email
    |> html_body(html)
    |> text_body(text)
  end
end
