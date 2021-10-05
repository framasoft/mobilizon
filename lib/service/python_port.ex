defmodule Mobilizon.PythonPort do
  @moduledoc """
  Port to use Python modules from Elixir
  """

  use Export.Python

  @doc """
  ## Parameters
    - path: directory to include in python path
  """
  @spec python_instance(String.t()) :: pid
  def python_instance(path) do
    python = "/usr/bin/python3"

    {:ok, pid} = Python.start(python: python, python_path: path)

    pid
  end

  @doc """
  Call python function using MFA format
  """
  @spec call_python(pid, binary, binary, list) :: any
  def call_python(pid, module, function, arguments \\ []) do
    Python.call(pid, module, function, arguments)
  end
end
