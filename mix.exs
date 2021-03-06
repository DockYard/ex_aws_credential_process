defmodule ExAwsCredentialProcess.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aws_credential_process,
      version: "1.0.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      docs: [
        main: "README.md",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExAwsCredentialProcess.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_aws, "~> 2.0"},
      {:ex_doc, "~> 0.16", only: [:dev, :test]},
      {:jason, ">= 1.1.2", only: [:dev, :test]},
      {:mox, "~> 0.5", only: :test},
      {:porcelain, "~> 2.0"}
    ]
  end

  defp package do
    [
      description:
        "Uses ex_aws to make requests to AWS, authenticated using cached credentials, which it refreshes as needed using the credential_process command you supply. ",
      maintainers: ["Nathan Long", "Luke Imhoff"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/DockYard/ex_aws_credential_process"}
    ]
  end
end
