defmodule ExAwsCredentialProcess.Refresh.AfterExpired do
  @moduledoc """
  Strategy for refreshing credentials only after they expire or a request
  fails.  In general, this is a bad idea, as it will probably mean that some
  requests fail before a new token is obtained. But if a system does not
  support refreshing tokens early, using this strategy will mean that you don't
  make pointless refresh requests.
  """
  @behaviour ExAwsCredentialProcess.Refresh
  @impl true
  @doc """
  Refresh if we've retried at all, or if the expiration datetime has passed.
  """
  def refresh?(expiration, now, retries) do
    retries > 0 || DateTime.compare(expiration, now) == :lt
  end
end
