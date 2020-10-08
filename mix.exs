defmodule TelemetricEvents.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetric_events,
      version: "0.0.0",
      description:
        "Uses `:telemetry` to take events and combines logging and Prometheus metrics to process events",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4"},
      {:ex_doc, "~> 0.22.6"}
    ]
  end

  def package() do
    [
      maintainers: ["thebriz24"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thebriz24/gen_timer"}
    ]
  end
end
