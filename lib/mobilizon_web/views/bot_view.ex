defmodule MobilizonWeb.BotView do
  use MobilizonWeb, :view
  alias MobilizonWeb.BotView

  def render("index.json", %{bots: bots}) do
    %{data: render_many(bots, BotView, "bot.json")}
  end

  def render("show.json", %{bot: bot}) do
    %{data: render_one(bot, BotView, "bot.json")}
  end

  def render("bot.json", %{bot: bot}) do
    %{id: bot.id, source: bot.source, type: bot.type}
  end
end
