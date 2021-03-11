# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/mix/tasks/pleroma/common.ex

defmodule Mix.Tasks.Mobilizon.Common do
  @moduledoc """
  Common functions to be reused in mix tasks
  """

  def start_mobilizon do
    if mix_task?(), do: Mix.Task.run("app.config")
    Application.put_env(:phoenix, :serve_endpoints, false, persistent: true)

    {:ok, _} = Application.ensure_all_started(:mobilizon)
  end

  def get_option(options, opt, prompt, defval \\ nil, defname \\ nil) do
    Keyword.get(options, opt) || shell_prompt(prompt, defval, defname)
  end

  def shell_prompt(prompt, defval \\ nil, defname \\ nil) do
    prompt_message = "#{prompt} [#{defname || defval}] "

    input =
      if mix_shell?(),
        do: Mix.shell().prompt(prompt_message),
        else: :io.get_line(prompt_message)

    case input do
      "\n" ->
        case defval do
          nil ->
            shell_prompt(prompt, defval, defname)

          defval ->
            defval
        end

      input ->
        String.trim(input)
    end
  end

  def shell_yes?(message) do
    if mix_shell?(),
      do: Mix.shell().yes?("Continue?"),
      else: shell_prompt(message, "Continue?") in ~w(Yn Y y)
  end

  @spec shell_info(String.t()) :: :ok
  def shell_info(message) do
    if mix_shell?(),
      do: Mix.shell().info(message),
      else: IO.puts(message)
  end

  @spec shell_error(String.t()) :: :ok
  def shell_error(message) do
    if mix_shell?(),
      do: Mix.shell().error(message),
      else: IO.puts(:stderr, message)
  end

  @doc "Performs a safe check whether `Mix.shell/0` is available (does not raise if Mix is not loaded)"
  def mix_shell?, do: :erlang.function_exported(Mix, :shell, 0)

  def mix_task?, do: :erlang.function_exported(Mix.Task, :run, 1)

  def escape_sh_path(path) do
    ~S(') <> String.replace(path, ~S('), ~S(\')) <> ~S(')
  end

  @type task_module :: atom

  @doc """
  Gets the shortdoc for the given task `module`.
  Returns the shortdoc or `nil`.
  """
  @spec shortdoc(task_module) :: String.t() | nil
  def shortdoc(module) when is_atom(module) do
    case List.keyfind(module.__info__(:attributes), :shortdoc, 0) do
      {:shortdoc, [shortdoc]} -> shortdoc
      _ -> nil
    end
  end

  def show_subtasks_for_module(module_name) do
    tasks = list_subtasks_for_module(module_name)

    max = Enum.reduce(tasks, 0, fn {name, _doc}, acc -> max(byte_size(name), acc) end)

    Enum.each(tasks, fn {name, doc} ->
      shell_info("#{String.pad_trailing(name, max + 2)} # #{doc}")
    end)
  end

  @spec list_subtasks_for_module(atom()) :: list({String.t(), String.t()})
  def list_subtasks_for_module(module_name) do
    Application.load(:mobilizon)
    {:ok, modules} = :application.get_key(:mobilizon, :modules)
    module_name = to_string(module_name)

    modules
    |> Enum.filter(fn module ->
      String.starts_with?(to_string(module), to_string(module_name)) &&
        to_string(module) != to_string(module_name)
    end)
    |> Enum.map(&format_module/1)
  end

  defp format_module(module) do
    {format_name(to_string(module)), shortdoc(module)}
  end

  defp format_name("Elixir.Mix.Tasks.Mobilizon." <> task_name) do
    String.downcase(task_name)
  end
end
