defmodule Kethel.MixProject do
  use Mix.Project

  def project do
    [
      app: :kethel,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp deps do
    [
      { :tzdata, "~> 1.1" },
      { :mustache, "~> 0.5.0" }
    ]
  end
end
