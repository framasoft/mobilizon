defmodule Mix.Tasks.GenerateConfig do
  use Mix.Task

  @moduledoc """
  Generate a new config

  ## Usage
  ``mix generate_config``

  This mix task is interactive, and will overwrite the environment file present at ``.env.production``.

  Inspired from Pleroma own generate_config task
  """
  def run(_) do
    IO.puts("Answer a few questions to generate a new config\n")

    override =
      if File.exists?(".env.production") do
        confirm("You already have an .env.production file, do you want to override it?")
      else
        nil
      end

    if override == true do
      IO.puts("\n--- THIS WILL OVERWRITE YOUR .env.production file! ---\n")
    end

    if override != false do
      domain = string_required("What is your domain name? (e.g. framameet.org): ")
      name = string_required("What is the name of your instance? (e.g. Framameet): ")
      email = email("What's your admin email address: ")

      if confirm("Is everything okay?") do
        do_generate(domain, name, email)
      else
        IO.puts("\nYou cancelled installation\n")
      end
    else
      IO.puts("\nYou cancelled installation\n")
    end
  end

  defp do_generate(domain, name, email) do
    secret = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

    # Try to avoid issues with some special caracters using url_encode64()
    dbpass = :crypto.strong_rand_bytes(64) |> Base.url_encode64() |> binary_part(0, 64)

    resultSql = EEx.eval_file("support/postgresql/setup_db.psql", database_password: dbpass)

    result =
      EEx.eval_file(
        ".env.production.sample",
        instance_domain: domain,
        instance_name: name,
        instance_email: email,
        instance_secret: secret,
        database_password: dbpass
      )

    IO.puts("\nWriting config to .env.production.\n\nCheck it and configure your database.")

    File.write(".env.production", result)

    IO.puts("""
    \nWriting setup_db.psql, please run it as postgres superuser, i.e.: sudo su postgres -c 'psql -f setup_db.psql'\n
    You may delete the setup_db.psql file once it has been executed.
    """)

    File.write("setup_db.psql", resultSql)
  end

  # Taken from ex_prompt
  @spec confirm(String.t()) :: boolean()
  defp confirm(prompt) do
    answer =
      String.trim(prompt)
      |> Kernel.<>(" [Yn] ")
      |> string()
      |> String.downcase()

    cond do
      answer in ~w(yes y) -> true
      answer in ~w(no n) -> false
      true -> confirm(prompt)
    end
  end

  # Taken from ex_prompt
  @spec string(String.t()) :: String.t()
  defp string(prompt) do
    case IO.gets(prompt) do
      :eof -> ""
      {:error, _reason} -> ""
      str -> String.trim_trailing(str)
    end
  end

  # Taken from ex_prompt
  @spec string_required(String.t()) :: String.t()
  defp string_required(prompt) do
    case string(prompt) do
      "" -> string_required(prompt)
      str -> str
    end
  end

  @spec email(String.t(), boolean()) :: String.t()
  defp email(prompt, required \\ true) do
    email_value =
      case required do
        true -> string_required(prompt)
        _ -> string(prompt)
      end

    case Mobilizon.Service.EmailChecker.valid?(email_value) do
      false -> email(prompt, required)
      _ -> email_value
    end
  end
end
