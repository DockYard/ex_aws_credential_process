defmodule ExAwsCredentialProcess.Refresh do
  @moduledoc """
  Behaviour for deciding whether to refresh credentials.
  """
  @doc """
  Receives the expiration datetime of the current credentials, the current
  datetime, and the number of times the current request has been retried.
  Must return a boolean.
  """
  @callback refresh?(expiration :: DateTime.t(), now :: DateTime.t(), retries :: integer) ::
              boolean
end
