defmodule PseudoGettext.MixProject do
  use Mix.Project

  def project do
    [
      app: :pseudo_gettext,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_other), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gettext, "> 0.0.0"},
      {:nimble_parsec, "~> 1.0"},
      {:jason, "> 0.0.0"},
      {:floki, "~> 0.3"}
    ]
  end
end
