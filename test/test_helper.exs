{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.configure(formatters: [ExUnit.CLIFormatter, ExUnitNotifier])

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Eventos.Repo, :manual)
