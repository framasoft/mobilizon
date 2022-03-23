{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter, ExUnitNotifier])

ExUnit.start()
