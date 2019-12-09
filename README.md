# ExAwsCredentialProcess

Uses `:ex_aws` to make requests to AWS, authenticated using cached credentials, which it refreshes as needed using the [`credential_process`](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes) command you supply.
Specifically, it retrieves, caches, and adds to `ExAws.request/1` calls the values of the `:access_key_id`, `:secret_access_key`, and `:security_token` options.

Once it's set up, you can simply use `ExAwsCredentialProcess.request/1` in place of `ExAws.request/1`.

For example:

```elixir
ExAws.S3.list_objects("my-bucket")
|> ExAwsCredentialProcess.request(region: "us-west-1")
```

This function handles sending along the current credentials.
It also notices when a request fails authentication, fetches fresh credentials, and retries one time.

If you prefer, you can call `ExAwsCredentialProcess.fetch_current_credentials/0` to pull them from the cache, then call `ExAws.request/1` yourself.

## Installation

Point your `mix.exs` repo usage to this git repo.

```elixir
def deps do
  [
    {:ex_aws_credential_process, "~> 0.1.0", git: "this-repo-url"}
  ]
end
```

## Configuration

`ex_aws_credential_process` needs the following configuration.

### `credential_process` command

`:ex_aws_credential_process` needs to know the `credential_process` command to run to fetch your AWS credentials.
You must provide the full command string as an argument to `ExAwsCredentialProcess.start_link/1` when you add it to your supervision tree.

For example:

```elixir
{ExAwsCredentialProcess, %{credential_process_cmd: credential_process_cmd()}}
```

You can get that command from an environment variable or wherever else you like.
One option is to specify it in your `~/.aws/config`, like this:

    [profile dev]
    credential_process = my_command -u some_user -a some_account -r some_role
    region = us-west-3

Then you can use `ExAws` to fetch the value from there:

```elixir
defp credential_process_cmd() do
  ExAws.CredentialsIni.security_credentials("dev")
  |> Map.fetch!(:credential_process)
end
```

### JSON library

`:ex_aws_credential_process` also needs to parse the JSON string your `credential_process` command returns, and for that, it needs a JSON library, which you must configure. For example:

```elixir
config :ex_aws_credential_process, :json_codec, Jason
```

Note that your command must return JSON which matches [Amazon's specification](https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes).

## Refresh Strategy

When starting `ExAwsCredentialProcess`, you may provide a refresh strategy in the form of a module that implements the `ExAwsCredentialProcess.Refresh` behaviour.
It must have a `refresh?/3` function, which will receive the credential expiration datetime, the current datetime, and how many times the request has retried, and must return a boolean.

The default strategy is to refresh only after the credentials are expired.
You might want to refresh (eg) about 30 minutes before expiration, but not during a certain time window, and always adding jitter among instances.
Pass your own strategy like this:

```elixir
{ExAwsCredentialProcess, %{credential_process_cmd: credential_process_cmd(), refresh_strategy: MyStrategy}}
```

The refresh strategy is checked when we are about to make a request or have just made a request and seen that it failed authentication.
We ensure that we don't fire off multiple `credential_process` commands concurrently.

We currently do not proactively refresh credentials before the expiration arrives.
The reason is that the `credential_process` this library was initially developed to work with does not support getting new credentials before the old ones expire.
If it's determined that 1) this can be fixed and 2) getting new credentials doesn't invalidate the old ones, thereby causing in-flight requests to fail, `ExAwsCredentialProcess` can easily be updated to periodically refresh before the expiration arrives.
