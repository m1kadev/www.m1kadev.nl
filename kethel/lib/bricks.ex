defmodule Bricks do
  @typedoc "A path, relative to mix.exs"
  @type relative_path() :: binary()

  @typedoc "The name of the brick"
  @type brick_name() :: binary()

  @typedoc "A valid mustache template"
  @type mustache() :: binary()

  @spec collect(relative_path()) :: %{ brick_name() => mustache() }
  def collect(folder) do
    Path.wildcard(folder <> "/bricks/*.thtml")
      |> Map.new(fn x -> { FileX.trimmed_filename(x), File.read!(x) } end)
  end
 end 
