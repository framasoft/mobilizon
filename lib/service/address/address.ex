defmodule Mobilizon.Service.Address do
  @moduledoc """
  Module to render an `Mobilizon.Addresses.Address` struct to a string
  """

  alias Mobilizon.Addresses.Address, as: AddressModel

  @type address :: %{name: String.t(), alternative_name: String.t()}

  @spec render_address(AddressModel.t()) :: String.t() | nil
  def render_address(%AddressModel{} = address) do
    %{name: name, alternative_name: alternative_name} = render_names(address)

    cond do
      defined?(alternative_name) && defined?(name) ->
        "#{name}, #{alternative_name}"

      defined?(name) ->
        name

      defined?(alternative_name) ->
        alternative_name

      true ->
        nil
    end
  end

  @spec render_address!(AddressModel.t()) :: String.t() | no_return
  def render_address!(%AddressModel{} = address) do
    case render_address(address) do
      nil ->
        raise ArgumentError, message: "Invalid address"

      address ->
        address
    end
  end

  @spec render_names(AddressModel.t()) :: address()
  def render_names(%AddressModel{type: nil} = address) do
    render_names(%AddressModel{address | type: "house"})
  end

  def render_names(%AddressModel{
        type: type,
        description: description,
        postal_code: postal_code,
        locality: locality,
        country: country
      })
      when type in ["house", "street", "secondary"] do
    %{
      name: description,
      alternative_name: [postal_code, locality, country] |> Enum.filter(& &1) |> Enum.join(", ")
    }
  end

  def render_names(%AddressModel{
        type: type,
        description: description,
        postal_code: postal_code,
        locality: locality,
        country: country
      })
      when type in ["zone", "city", "administrative"] do
    %{
      name: if(defined?(postal_code), do: "#{description} (#{postal_code})", else: description),
      alternative_name:
        [locality, country]
        |> Enum.filter(&(&1 && &1 != description))
        |> Enum.join(", ")
    }
  end

  def render_names(%AddressModel{
        description: description,
        street: street,
        region: region,
        locality: locality,
        country: country
      }) do
    alternative_name =
      cond do
        defined?(street) ->
          if defined?(locality), do: "#{street} (#{locality})", else: street

        defined?(locality) and locality != region ->
          "#{locality}, #{region}, #{country}"

        defined?(region) ->
          "#{region}, #{country}"

        defined?(country) ->
          country

        true ->
          nil
      end

    %{name: description, alternative_name: alternative_name}
  end

  defp defined?(string) when is_binary(string), do: String.trim(string) != ""
  defp defined?(_), do: false
end
