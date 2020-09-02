# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/workers/worker_helper.ex

defmodule Mobilizon.Service.Workers.Helper do
  @moduledoc """
  Tools to ease dealing with workers
  """

  alias Mobilizon.Config
  alias Mobilizon.Service.Workers.Helper

  def worker_args(queue) do
    case Config.get([:workers, :retries, queue]) do
      nil -> []
      max_attempts -> [max_attempts: max_attempts]
    end
  end

  def sidekiq_backoff(attempt, pow \\ 4, base_backoff \\ 15) do
    backoff =
      :math.pow(attempt, pow) +
        base_backoff +
        :rand.uniform(2 * base_backoff) * attempt

    trunc(backoff)
  end

  defmacro __using__(opts) do
    caller_module = __CALLER__.module
    queue = Keyword.fetch!(opts, :queue)

    quote do
      # Note: `max_attempts` is intended to be overridden in `new/2` call
      use Oban.Worker,
        queue: unquote(queue),
        max_attempts: 1

      alias Oban.Job

      def enqueue(operation, params, worker_args \\ []) do
        params = Map.merge(%{"op" => operation}, params)
        queue_atom = String.to_existing_atom(unquote(queue))
        worker_args = worker_args ++ Helper.worker_args(queue_atom)

        unquote(caller_module)
        |> apply(:new, [params, worker_args])
        |> Oban.insert()
      end
    end
  end
end
