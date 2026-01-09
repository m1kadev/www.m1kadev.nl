defmodule Pages do
  def collect(context) do
    pages_root = context.project_root <> "/pages"
    pages = Path.wildcard(pages_root <> "/**/*.fxg")
      |> Enum.map(fn path -> { path, File.read!(path) } end)
      |> Enum.map(fn { path, data } -> { KernelX.binary_slice_from(path, byte_size(pages_root)), data } end)
  end
end
