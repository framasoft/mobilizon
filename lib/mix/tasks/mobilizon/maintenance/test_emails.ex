defmodule Mix.Tasks.Mobilizon.Maintenance.TestEmails do
  @moduledoc """
  Task to send an email to check if the configuration is running properly
  """
  use Mix.Task
  import Mix.Tasks.Mobilizon.Common
  alias Mobilizon.Config
  alias Mobilizon.Web.Email

  @shortdoc "Send an email to check if the configuration is running properly"

  @impl Mix.Task
  def run(options) do
    {options, args, []} =
      OptionParser.parse(
        options,
        strict: [
          locale: :string,
          help: :boolean
        ],
        aliases: [
          l: :locale,
          h: :help
        ]
      )

    if Keyword.get(options, :help, false) do
      show_help()
    end

    if Enum.empty?(args) do
      shell_error("mobilizon.maintenance.test_emails requires an email as argument")
    end

    start_mobilizon()

    default_language = Config.default_language()

    args
    |> hd()
    |> String.trim()
    |> Email.Admin.email_configuration_test(
      locale: Keyword.get(options, :locale, default_language)
    )
    |> Email.Mailer.send_email()
  end

  defp show_help do
    shell_info("""
    mobilizon.maintenance.test_emails [-h/--help] [email]

    This command allows to send an email to an address in order to verify if email works

    Options:

      -l/--locale
              Locale for the mail message (en_US, de_DE, …)

      -h/--help
              Show the help
    """)

    shutdown(error_code: 0)
  end
end
