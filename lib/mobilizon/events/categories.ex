defmodule Mobilizon.Events.Categories do
  @moduledoc """
  Module that handles event categories
  """
  import Mobilizon.Web.Gettext

  @default "MEETING"

  @spec default :: String.t()
  def default do
    @default
  end

  @spec list :: [%{id: atom(), label: String.t()}]
  def list do
    build_in_categories() ++ extra_categories()
  end

  @spec get_category(String.t() | nil) :: String.t()
  def get_category(category) do
    if category in Enum.map(list(), &String.upcase(to_string(&1.id))) do
      category
    else
      default()
    end
  end

defp build_in_categories do
  [
    %{
      id: :bildung,
      label: gettext("Bildung")
    },
    %{
      id: :bildungsurlaub,
      label: gettext("Bildungsurlaub")
    },
    %{
      id: :streik,
      label: gettext("Streik")
    },
    %{
      id: :vorbereitungstreffen,
      label: gettext("Vorbereitungstreffen")
    },
    %{
      id: :musik,
      label: gettext("Musik")
    },
    %{
      id: :kreativ,
      label: gettext("Kreativ")
    },
    %{
      id: :aktion_demo,
      label: gettext("Aktion/Demo")
    },
    %{
      id: :offenes_plenum,
      label: gettext("Offenes Plenum")
    },
    # Standardkategorie
    %{
      id: :meeting,
      label: gettext("Veranstaltung")
    }
  ]
end

  @spec extra_categories :: [%{id: atom(), label: String.t()}]
  defp extra_categories do
    :mobilizon
    |> Application.get_env(:instance)
    |> Keyword.get(:extra_categories, [])
  end
end