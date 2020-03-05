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

Install `goon`, which allows for capturing `stderr` if there is an error, for easier debugging.

1. Go to https://github.com/alco/goon/releases
2. Download the tarball for your system from the latest release.
3. `tar xvfz goon*.tar.gz`
4. Put it somewhere in your PATH (or into the directory that will become the current working directory of your application): `mv goon ...`
5. `rm goon*.tar.gz`

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

The library ships with two refresh strategies: `ExAwsCredentialProcess.Refresh.AfterExpired` (the default) which refreshes only after the expiration datetime arrives, and `ExAwsCredentialProcess.Refresh.BeforeExpiredWithJitter`, which has an increasing chance of refreshing in the last 30 minutes before expiration and will definitely refresh once the expiration arrives.

You can pass your own strategy like this:

```elixir
{ExAwsCredentialProcess, %{credential_process_cmd: credential_process_cmd(), refresh_strategy: MyStrategy}}
```
