defmodule MobilizonWeb.Schema.Utils do
  def handle_errors(fun) do
    fn source, args, info ->
      case Absinthe.Resolution.call(fun, source, args, info) do
        {:error, %Ecto.Changeset{} = changeset} -> format_changeset(changeset)
        val -> val
      end
    end
  end

  def format_changeset(changeset) do
    # {:error, [email: {"has already been taken", []}]}
    errors =
      changeset.errors
      |> Enum.map(fn {_key, {value, context}} ->
        [message: "#{value}", details: context]
      end)

    {:error, errors}
  end
end
