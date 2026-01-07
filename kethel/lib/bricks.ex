defmodule Bricks do
  @typedoc "A path, relative to mix.exs"
  @type relative_path() :: String.t()

  @typedoc "The name of the brick"
  @type brick_name() :: String.t()

  @typedoc "A valid mustache template"
  @type mustache() :: String.t()

  @spec collect(relative_path()) :: %{brick_name() => mustache()}
  def collect(folder) do
    Path.wildcard(folder <> "/bricks/*.thtml")
      |> Enum.map(fn brick -> { brick, File.read!(brick) } end) 
      |> Enum.map(fn { brick, contents } -> { Path.basename(brick) |> Path.rootname(), contents } end) # "../bricks/base_header.html" would beccome just "base_header"
  end
 end 
