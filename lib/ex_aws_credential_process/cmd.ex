defmodule ExAwsCredentialProcess.Cmd do
  @moduledoc """
  Behaviour for supporting updating :ex_aws AWS credentials using a credential_process command
  """

  @callback fetch_new_credentials(map) ::
              {:ok, list(), DateTime.t()}
              | {:error, :credential_process_error, :invalid_json, String.t()}
              | {:error, :credential_process_error, :invalid_credentials_map, String.t()}
              | {:error, :credential_process_error, :invalid_expiration, String.t()}

  defdelegate fetch_new_credentials(params), to: ExAwsCredentialProcess.Cmd.Impl
end
