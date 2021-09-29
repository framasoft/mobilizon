# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/web/federator/federator.ex

defmodule Mobilizon.Federation.ActivityPub.Federator do
  @moduledoc """
  Handle federated activities
  """

  use GenServer

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Federation.ActivityPub
  alias Mobilizon.Federation.ActivityPub.Actor, as: ActivityPubActor
  alias Mobilizon.Federation.ActivityPub.Transmogrifier

  require Logger

  @max_jobs 20

  @spec init(any()) :: {:ok, any()}
  def init(args) do
    {:ok, args}
  end

  @spec start_link(any) :: GenServer.on_start()
  def start_link(_) do
    spawn(fn ->
      # 1 minute
      Process.sleep(1000 * 60)
    end)

    GenServer.start_link(
      __MODULE__,
      %{
        in: {:sets.new(), []},
        out: {:sets.new(), []}
      },
      name: __MODULE__
    )
  end

  @spec handle(:publish | :publish_single_ap | atom(), Activity.t() | map()) ::
          :ok | {:ok, Activity.t()} | Tesla.Env.result() | {:error, String.t()}
  def handle(:publish, activity) do
    Logger.debug(inspect(activity))
    Logger.debug(fn -> "Running publish for #{activity.data["id"]}" end)

    with {:ok, %Actor{} = actor} <-
           ActivityPubActor.get_or_fetch_actor_by_url(activity.data["actor"]) do
      Logger.info(fn -> "Sending #{activity.data["id"]} out via AP" end)
      ActivityPub.Publisher.publish(actor, activity)
    end
  end

  def handle(:incoming_ap_doc, params) do
    Logger.info("Handling incoming AP activity")
    Logger.debug(inspect(Map.drop(params, ["@context"])))

    case Transmogrifier.handle_incoming(params) do
      {:ok, activity, _data} ->
        {:ok, activity}

      e ->
        # Just drop those for now
        Logger.debug("Unhandled activity")
        Logger.debug(inspect(e))
        Logger.debug(Jason.encode!(params))
    end
  end

  def handle(:publish_single_ap, params) do
    ActivityPub.Publisher.publish_one(params)
  end

  def handle(type, _) do
    Logger.debug(fn -> "Unknown task: #{type}" end)
    {:error, "Don't know what to do with this"}
  end

  @spec enqueue(atom(), map(), pos_integer()) :: :ok | {:ok, any()} | {:error, any()}
  def enqueue(type, payload, priority \\ 1) do
    Logger.debug("enqueue something with type #{inspect(type)}")

    if Application.fetch_env!(:mobilizon, :env) == :test do
      handle(type, payload)
    else
      GenServer.cast(__MODULE__, {:enqueue, type, payload, priority})
    end
  end

  @spec maybe_start_job(any(), any()) :: {any(), any()}
  def maybe_start_job(running_jobs, queue) do
    if :sets.size(running_jobs) < @max_jobs && queue != [] do
      {{type, payload}, queue} = queue_pop(queue)
      {:ok, pid} = Task.start(fn -> handle(type, payload) end)
      mref = Process.monitor(pid)
      {:sets.add_element(mref, running_jobs), queue}
    else
      {running_jobs, queue}
    end
  end

  @spec handle_cast(any(), any()) :: {:noreply, any()}
  def handle_cast({:enqueue, type, payload, _priority}, state)
      when type in [:incoming_doc, :incoming_ap_doc] do
    %{in: {i_running_jobs, i_queue}, out: {o_running_jobs, o_queue}} = state
    i_queue = enqueue_sorted(i_queue, {type, payload}, 1)
    {i_running_jobs, i_queue} = maybe_start_job(i_running_jobs, i_queue)
    {:noreply, %{in: {i_running_jobs, i_queue}, out: {o_running_jobs, o_queue}}}
  end

  def handle_cast({:enqueue, type, payload, _priority}, state) do
    %{in: {i_running_jobs, i_queue}, out: {o_running_jobs, o_queue}} = state
    o_queue = enqueue_sorted(o_queue, {type, payload}, 1)
    {o_running_jobs, o_queue} = maybe_start_job(o_running_jobs, o_queue)
    {:noreply, %{in: {i_running_jobs, i_queue}, out: {o_running_jobs, o_queue}}}
  end

  def handle_cast(m, state) do
    Logger.debug(fn ->
      "Unknown: #{inspect(m)}, #{inspect(state)}"
    end)

    {:noreply, state}
  end

  @spec handle_info({:DOWN, any(), :process, any, any()}, any) :: {:noreply, map()}
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    %{in: {i_running_jobs, i_queue}, out: {o_running_jobs, o_queue}} = state
    i_running_jobs = :sets.del_element(ref, i_running_jobs)
    o_running_jobs = :sets.del_element(ref, o_running_jobs)
    {i_running_jobs, i_queue} = maybe_start_job(i_running_jobs, i_queue)
    {o_running_jobs, o_queue} = maybe_start_job(o_running_jobs, o_queue)

    {:noreply, %{in: {i_running_jobs, i_queue}, out: {o_running_jobs, o_queue}}}
  end

  @spec enqueue_sorted(any(), any(), pos_integer()) :: any()
  def enqueue_sorted(queue, element, priority) do
    [%{item: element, priority: priority} | queue]
    |> Enum.sort_by(fn %{priority: priority} -> priority end)
  end

  @spec queue_pop(list(any())) :: {any(), list(any())}
  def queue_pop([%{item: element} | queue]) do
    {element, queue}
  end
end
