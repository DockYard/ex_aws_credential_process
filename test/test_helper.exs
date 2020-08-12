ExUnit.start()

Application.put_env(
  :ex_aws_credential_process,
  :credential_process,
  MockExAwsCredentialProcess.Cmd
)
