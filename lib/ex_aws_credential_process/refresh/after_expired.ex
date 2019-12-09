defmodule ExAwsCredentialProcess.Refresh.AfterExpired do
  @moduledoc """
  Strategy for refreshing credentials only after they expire or a request fails
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
