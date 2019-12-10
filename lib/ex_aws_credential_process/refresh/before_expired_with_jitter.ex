defmodule ExAwsCredentialProcess.Refresh.BeforeExpiredWithJitter do
  @moduledoc """
  Strategy for refreshing credentials before expiration, with jitter.
  The jitter is so that in a busy system, multiple hosts don't all refresh
  at the same moment.
  """
  @behaviour ExAwsCredentialProcess.Refresh
  @impl true
  @jitter_window_seconds 30 * 60
  @doc """
  Refresh if we've retried at all, or if the expiration datetime has passed.
  """

  def refresh?(_expiration, _now, retries) when retries > 0, do: true

  def refresh?(expiration, now, _retries) do
    seconds_remaining = DateTime.diff(expiration, now, :second)

    cond do
      # expired
      seconds_remaining <= 0 ->
        true

      # expiration not yet in the jitter window
      seconds_remaining > @jitter_window_seconds ->
        false

      # during jitter window, increasing chance of refresh
      true ->
        :rand.uniform(@jitter_window_seconds) >= seconds_remaining
    end
  end
end
