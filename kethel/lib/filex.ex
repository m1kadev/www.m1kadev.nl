defmodule FileX do
  @typedoc "Any path"
  @type path() :: binary()

  @spec trimmed_filename(path()) :: binary()
  def trimmed_filename(path) do
    Path.basename(path) |> Path.rootname()
  end
end
