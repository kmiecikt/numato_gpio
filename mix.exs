defmodule NumatoGpio.MixProject do
  use Mix.Project

  def project do
    [
      app: :numato_gpio,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {NumatoGpio.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 1.0.0"},
      {:circuits_uart, "~> 1.3"}
    ]
  end
end
