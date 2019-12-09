defmodule ExAwsCredentialProcess do
  @moduledoc """
  Keeps a cache of current AWS credentials, fetched using the provided `credential_process` command.
  Provides functionality to make requests with ExAws, adding the cached AWS credentials; will refresh credentials and retry if a request fails auth.
  Also allows fetching the current credentials for direct usage.

  You must add this GenServer to your application's supervision tree, providing it the command-line command you use to fetch fresh credentials, which must behave as described in [the AWS docs](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes).
  For example:

      {ExAwsCredentialProcess, %{credential_process_cmd: "my_cmd -user me -role foo"}}
      # or
      {ExAwsCredentialProcess, %{
        credential_process_cmd: "my_cmd -user me -role foo",
        refresh_strategy: MyStrategy
      }}
  """
  use GenServer
  @table_name :ex_aws_credential_process_cache

  @doc """
  Start the cache GenServer, keeping a record of the given
  `credential_process` command so that AWS credentials can be fetched and
  refreshed as needed.
  """
  def start_link(%{credential_process_cmd: credential_process_cmd} = opts) do
    GenServer.start_link(
      __MODULE__,
      %{
        credential_process_cmd: credential_process_cmd,
        refresh_strategy:
          Map.get(opts, :refresh_strategy, ExAwsCredentialProcess.Refresh.AfterExpired)
      },
      name: __MODULE__
    )
  end

  @doc false
  def init(state) do
    unless state.refresh_strategy do
      raise ArgumentError, "no refresh strategy was provided"
    end

    :ets.new(@table_name, [:set, :named_table, :protected, read_concurrency: true])
    {:ok, state}
  end

  @doc """
  Make a request, delegating to `ExAws.request/1`.
  Accepts an `option` keyword list argument and merges in AWS crdentials, retrieved from
  `fetch_current_credentials/1`.
  If a request fails authentication, refreshes the credentials and retries one time.
  """
  def request(request, opts \\ []) do
    do_request(request, opts, 0)
  end

  @doc """
  Fetch current credentials for AWS from the cache, which is populated using
  the `credential_process` command given to the GenServer at boot.

  Returns `{:ok, credentials}` or `{:error, error}`.

  This function is used by `request/1` to supply the needed credentials; you do
  not need to call it unless you prefer to call `ExAws.request/1` yourself.
  """
  def fetch_current_credentials(retries \\ 0) do
    case :ets.lookup(@table_name, :credentials) do
      [{:credentials, creds, expiration, refresh_strategy}] ->
        if refresh_strategy.refresh?(expiration, DateTime.utc_now(), retries) do
          refresh_credentials()
        else
          {:ok, creds}
        end

      # credentials not found; fetch them
      _ ->
        refresh_credentials()
    end
  end

  def handle_call(:refresh_credentials, _from, state) do
    case ExAwsCredentialProcess.Cmd.fetch_new_credentials(state.credential_process_cmd) do
      {:ok, credentials, expiration} ->
        :ets.insert(@table_name, {:credentials, credentials, expiration, state.refresh_strategy})
        {:reply, {:ok, credentials}, state}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  defp do_request(request, opts, retries) do
    with {:creds, {:ok, creds}} <- {:creds, fetch_current_credentials(retries)},
         {:request, {:ok, response}} <-
           {:request, ExAws.request(request, Keyword.merge(creds, opts))} do
      {:ok, response}
    else
      {:creds, error} ->
        error

      # missing required key
      {:request, {:error, "Required key: " <> _}} ->
        retry(request, opts, retries)

      # credentials expired or malformed
      {:request, {:error, {:http_error, code, _body}}} when code in [400, 403] ->
        retry(request, opts, retries)

      # any other request error
      {:request, error} ->
        error
    end
  end

  defp retry(_request, _opts, retries) when retries > 1 do
    {:error, :could_not_fetch_credentials}
  end

  defp retry(request, opts, retries) do
    do_request(request, opts, retries + 1)
  end

  defp refresh_credentials() do
    GenServer.call(__MODULE__, :refresh_credentials)
  end
end
