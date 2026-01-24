require Rambo

defmodule Pages do
  defstruct [:source_files, :main_template, :project_root, :bricks]

  defp trim_abs_path(path, project_root) do
    # ROOT + pages/
    begin = byte_size(project_root) + byte_size("pages/")
    # remove extension
    binary_part(path, begin, byte_size(path) - begin - byte_size(".fxg"))
  end

  @spec collect(%Context{}, Bricks.bricks()) :: %Pages{}
  def collect(project_root, bricks) do
    pages_root = project_root <> "/pages"

    %Pages{
      project_root: project_root,
      source_files:
        Path.wildcard(pages_root <> "/**/*.fxg")
        |> Task.async_stream(fn path -> {trim_abs_path(path, project_root), File.read!(path)} end)
        # we assume every file read succeeds :)) always be positive
        |> Enum.map(fn {:ok, val} -> val end),
      main_template: File.read!(project_root <> "/templates/base.thtml"),
      bricks: bricks
    }
  end

  @spec compile(%Pages{}) :: none()
  def compile(pages) do
    t_begin = System.monotonic_time(:millisecond)
    Task.async_stream(pages.source_files, fn page -> compile_file(pages, page) end)
    |> Enum.to_list()
    t_end = System.monotonic_time(:millisecond)
    t_end - t_begin 
  end

  # doc "compiles a file, already read into process memory. Does not return the binary, but instantly writes it to disk"
  @spec compile_file(%Pages{}, {}) :: none()
  defp compile_file(pages, {page_path, page_data}) do
    output_path = "#{pages.project_root}/build#{page_path}.html"
    # check for a custom template
    custom_template_path = "#{pages.project_root}/templates/pages#{page_path}.thtml"

    template =
      case File.read(custom_template_path) do
        {:ok, custom_template} -> custom_template
        {:error, :enoent} -> pages.main_template
        {:error, err} -> raise err
      end

    mustache_context =
      Map.merge(%{fxg_content: invoke_fxg(page_data), location: page_path}, pages.bricks)

    page_rendered = Mustache.render(template, mustache_context)
    File.write!(output_path, page_rendered)
    IO.puts("[COMPILED] #{pages.project_root}/pages#{page_path}.fxg -> #{output_path}")
  end

  # doc "Invokes the fxg compiler, a la `fxg -`, piping `data` into the process stdin, and reading the stdout. "
  @spec invoke_fxg(binary()) :: binary()
  defp invoke_fxg(data) do
    {:ok, res} = Rambo.run("fxg", ["-"], in: data)
    res.out
  end
end
