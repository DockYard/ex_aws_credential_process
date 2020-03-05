defmodule ExAwsCredentialProcess.CmdTest do
  use ExUnit.Case, async: true
  alias ExAwsCredentialProcess.Cmd

  setup_all do
    Application.put_env(:ex_aws_credential_process, :json_codec, Jason)
  end

  test "parses and returns valid data from the command" do
    creds = Cmd.fetch_new_credentials("test/support/successful.sh")

    assert {:ok,
            [
              access_key_id: "some_access_key_id",
              secret_access_key: "some_secret_access_key",
              security_token: "some_session_token"
            ], ~U[2019-11-22 18:32:33.000Z]} = creds
  end


  test "parses and returns valid data from the command even if it prints to stderr" do
    creds = Cmd.fetch_new_credentials("test/support/successful_with_stderr.sh")

    assert {:ok,
             [
               access_key_id: "some_access_key_id",
               secret_access_key: "some_secret_access_key",
               security_token: "some_session_token"
             ], ~U[2019-11-22 18:32:33.000Z]} = creds
  end

  test "returns an error when the command returns an invalid map" do
    {:error, err} = Cmd.fetch_new_credentials("test/support/invalid_map.sh")

    assert err ==
             {:credential_process_error, :invalid_credentials_map, "{\"chunky\": \"bacon\"}\n"}
  end

  test "returns an error when the command returns invalid json" do
    {:error, err} = Cmd.fetch_new_credentials("test/support/invalid_data.sh")
    assert err == {:credential_process_error, :invalid_json, "ohai\n"}
  end

  test "returns an error when the command fails" do
    {:error, err} = Cmd.fetch_new_credentials("test/support/failed.sh")
    assert err == {:credential_process_error, :invalid_json, ""}
  end
end
