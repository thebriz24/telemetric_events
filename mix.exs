defmodule TelemetricEvents.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetric_events,
      version: "0.2.0",
      description:
        "Uses `:telemetry` to take events and combines logging and Prometheus metrics to process events",
      elixir: ">= 1.10.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :prometheus_ex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: [:dev, :test], runtime: false},
      {:jason, ">= 1.0.0"},
      {:prometheus_ex, ">= 2.0.0 and < 4.0.0"},
      {:telemetry, ">= 0.4.0"}
    ]
  end

  defp elixirc_paths(env) when env == :test do
    ["lib", "test/support"]
  end

  defp elixirc_paths(_env) do
    ["lib"]
  end

  def package() do
    [
      maintainers: ["thebriz24"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thebriz24/telemetric_events"}
    ]
  end
end
