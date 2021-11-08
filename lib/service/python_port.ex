defmodule Mobilizon.PythonPort do
  @moduledoc """
  Port to use Python modules from Elixir
  """

  use Export.Python

  @python_path "/usr/bin/python3"

  @doc """
  Whether Python3 is installed
  """
  @spec python_exists? :: boolean
  def python_exists? do
    File.exists?(python_path())
  end

  @doc """
  ## Parameters
    - path: directory to include in python path
  """
  @spec python_instance(String.t()) :: pid
  def python_instance(path) do
    {:ok, pid} = Python.start(python: python_path(), python_path: path)

    pid
  end

  @doc """
  Call python function using MFA format
  """
  @spec call_python(pid, binary, binary, list) :: any
  def call_python(pid, module, function, arguments \\ []) do
    Python.call(pid, module, function, arguments)
  end

  @spec python_path :: String.t()
  defp python_path do
    case get_in(Application.get_env(:mobilizon, __MODULE__), [:path]) do
      path when is_binary(path) -> path
      nil -> @python_path
    end
  end
end
