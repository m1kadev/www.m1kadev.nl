defmodule Bricks do
  @typedoc "A path, relative to mix.exs"
  @type relative_path() :: binary()

  @typedoc "The name of the brick"
  @type brick_name() :: binary()

  @typedoc "A valid mustache template"
  @type mustache() :: binary()

  @spec collect(relative_path()) :: [ { brick_name(), mustache() } ]
  def collect(folder) do
    Path.wildcard(folder <> "/bricks/*.thtml")
      |> Enum.map(fn brick -> { brick, File.read!(brick) } end) 
      |> Enum.map(fn { brick, contents } -> { FileX.trimmed_filename(brick), contents } end) # "../bricks/base_header.html" would beccome just "base_header"
  end
 end 
