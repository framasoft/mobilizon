defmodule Mobilizon.PythonWorker do
  @moduledoc """
  Genserver to handle an instance of Python handling the calls to `Mobilizon.PythonPort`.
  """

  use GenServer
  use Export.Python

  alias Mobilizon.PythonPort

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec init(any) :: {:ok, %{python_pid: pid}}
  def init(_) do
    path = Path.join([:code.priv_dir(:mobilizon), "python"])
    pid = PythonPort.python_instance(path)

    {:ok, %{python_pid: pid}}
  end

  def terminate(_reason, %{python_pid: pid}) do
    Python.stop(pid)
  end

  @spec generate_pdf(String.t()) :: any
  def generate_pdf(html) do
    GenServer.call(__MODULE__, %{html: html, format: :pdf})
  end

  @spec generate_ods(String.t()) :: any
  def generate_ods(data) do
    GenServer.call(__MODULE__, %{data: data, format: :ods})
  end

  @spec has_module(String.t()) :: any
  def has_module(module) do
    GenServer.call(__MODULE__, %{module: module})
  end

  @spec handle_call(
          %{html: String.t(), format: :pdf} | %{data: String.t(), format: :ods},
          any(),
          map()
        ) :: {:reply, String.t(), map()}
  def handle_call(%{html: html, format: :pdf}, _from, %{python_pid: pid} = state) do
    res = PythonPort.call_python(pid, "pdf", "generate", [html])

    {:reply, res, state}
  end

  def handle_call(%{data: data, format: :ods}, _from, %{python_pid: pid} = state) do
    res = PythonPort.call_python(pid, "ods", "generate", [data])

    {:reply, res, state}
  end

  def handle_call(%{module: module}, _from, %{python_pid: pid} = state) do
    res = PythonPort.call_python(pid, "module", "has_package", [module])

    {:reply, res, state}
  end
end
