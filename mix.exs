defmodule WwwBuilder.MixProject do
  use Mix.Project

  def project do
    [
      app: :www_builder,
      version: "1.0.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:tzdata, "~> 1.1"}]
  end
end
