defmodule ExAwsCredentialProcessTest do
  use ExUnit.Case
  doctest ExAwsCredentialProcess

  import Mox

  @table_name :ex_aws_credential_process_cache

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    state = %{
      credential_process_cmd: "fake",
      refresh_strategy: ExAwsCredentialProcess.Refresh.AfterExpired
    }

    initial_credentials = [
      access_key_id: "1234AKI",
      secret_access_key: "1234SAK",
      security_token: "1234ST"
    ]

    {:ok, _pid} = ExAwsCredentialProcess.start_link(state)
    %{initial_credentials: initial_credentials}
  end

  test "a second refresh credentials request within expiration time will not fetch new credentials",
       %{initial_credentials: initial_credentials} do
    expiration = DateTime.add(DateTime.utc_now(), 3600, :second)

    MockExAwsCredentialProcess.Cmd
    |> expect(:fetch_new_credentials, fn _ -> {:ok, initial_credentials, expiration} end)

    assert GenServer.call(ExAwsCredentialProcess, :refresh_credentials) ==
             {:ok, initial_credentials}

    assert GenServer.call(ExAwsCredentialProcess, :refresh_credentials) ==
             {:ok, initial_credentials}
  end

  test "a second refresh credentials request after expiration time will fetch new credentials", %{
    initial_credentials: initial_credentials
  } do
    expiration = DateTime.add(DateTime.utc_now(), 1, :microsecond)
    new_expiration = DateTime.add(DateTime.utc_now(), 3600, :second)

    new_credentials = [
      access_key_id: "234AKI",
      secret_access_key: "234SAK",
      security_token: "234ST"
    ]

    MockExAwsCredentialProcess.Cmd
    |> expect(:fetch_new_credentials, fn _ -> {:ok, initial_credentials, expiration} end)
    |> expect(:fetch_new_credentials, fn _ ->
      {:ok, new_credentials, new_expiration}
    end)

    assert GenServer.call(ExAwsCredentialProcess, :refresh_credentials) ==
             {:ok, initial_credentials}

    assert GenServer.call(ExAwsCredentialProcess, :refresh_credentials) ==
             {:ok, new_credentials}
  end

  test "if there are no credential entries in the cache, a refresh credentials request fetches credentials and caches them",
       %{
         initial_credentials: initial_credentials
       } do
    expiration = DateTime.add(DateTime.utc_now(), 1, :microsecond)

    MockExAwsCredentialProcess.Cmd
    |> expect(:fetch_new_credentials, fn _ -> {:ok, initial_credentials, expiration} end)

    assert GenServer.call(ExAwsCredentialProcess, :refresh_credentials) ==
             {:ok, initial_credentials}

    assert :ets.lookup(@table_name, :credentials) == [
             {:credentials,
              [access_key_id: "1234AKI", secret_access_key: "1234SAK", security_token: "1234ST"],
              expiration, ExAwsCredentialProcess.Refresh.AfterExpired}
           ]
  end
end
