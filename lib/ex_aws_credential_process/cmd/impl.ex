defmodule ExAwsCredentialProcess.Cmd.Impl do
  @moduledoc """
  Supports updating :ex_aws AWS credentials using a credential_process command
  """

  @behaviour ExAwsCredentialProcess.Cmd

  require Logger

  @doc """
  Fetches new AWS credentials using the given credential_process command and,
  if sucessful, updates the global :ex_aws configuration accordingly
  """
  def fetch_new_credentials(credential_process_cmd) do
    with {:ok, raw_result} <- run(credential_process_cmd) do
      parse(raw_result)
    end
  end

  defp run(credential_process_cmd) do
    case Porcelain.shell(credential_process_cmd, err: :string) do
      %Porcelain.Result{status: 0, out: out} ->
        # This result must conform to the specification here:
        # https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes
        {:ok, out}

      %Porcelain.Result{status: status, err: err, out: out} ->
        {:error,
         {:credential_process_error, :non_zero_exit_status, %{status: status, err: err, out: out}}}
    end
  end

  defp parse(raw_result) do
    json_codec = Application.fetch_env!(:ex_aws_credential_process, :json_codec)

    with {:decode, {:ok, m}} when is_map(m) <- {:decode, json_codec.decode(raw_result)},
         {:valid_map,
          %{
            "AccessKeyId" => access_key_id,
            "SecretAccessKey" => secret_access_key,
            "SessionToken" => session_token,
            "Expiration" => expiration
          }} <- {:valid_map, m},
         {:valid_expiration, {:ok, expiration, 0}} <-
           {:valid_expiration, DateTime.from_iso8601(expiration)} do
      {:ok,
       [
         access_key_id: access_key_id,
         secret_access_key: secret_access_key,
         security_token: session_token
       ], expiration}
    else
      {:decode, _} ->
        {:error, {:credential_process_error, :invalid_json, raw_result}}

      {:valid_map, _} ->
        {:error, {:credential_process_error, :invalid_credentials_map, raw_result}}

      {:valid_expiration, _} ->
        {:error, {:credential_process_error, :invalid_expiration, raw_result}}
    end
  end
end
