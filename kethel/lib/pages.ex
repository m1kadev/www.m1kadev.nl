require Rambo

defmodule Pages do
  defstruct [ :source_files, :main_template, :project_root, :bricks ]

  def trim_abs_path(path, context) do
    begin = byte_size(context.project_root) + byte_size("pages/") # ROOT + pages/ 
    binary_part(path, begin, byte_size(path) - begin - byte_size(".fxg")) # remove extension
  end

  @spec collect(%Context{}) :: %Pages{}
  def collect(context) do
    pages_root = context.project_root <> "/pages"
    %Pages{
      project_root: context.project_root,
      source_files: Path.wildcard(pages_root <> "/**/*.fxg")
        |> Enum.map(fn path -> { path, File.read!(path) } end)
        |> Enum.map(fn { path, data } -> { trim_abs_path(path, context), data } end),
      main_template: File.read!(context.project_root <> "/templates/base.thtml"),
      bricks: context.bricks,
    }
  end

  @spec compile(%Pages{}) :: none()
  def compile(pages) do
    Task.async_stream(pages.source_files, fn page -> compile_file(pages, page) end) |> Enum.to_list()
  end

  @doc "compiles a file, already read into process memory. Does not return the binary, but instantly writes it to disk"
  @spec compile_file(%Pages{}, {  }) :: none()
  defp compile_file(pages, { page_path, page_data }) do
    output_path = "#{pages.project_root}/build#{page_path}.html"
    IO.puts("#{pages.project_root}/pages#{page_path}.fxg -> #{output_path}")
    # check for a custom template
    custom_template_path = "#{pages.project_root}/templates/pages#{page_path}.thtml"
    template = case File.read(custom_template_path) do
      {:ok, custom_template} -> custom_template
      {:error, :enoent} -> pages.main_template
      {:error, err } -> raise err
    end
    mustache_context = Map.merge(%{fxg_content: invoke_fxg(page_data), location: page_path}, pages.bricks)
    page_rendered = Mustache.render(template, mustache_context)
    File.write!(output_path, page_rendered)
  end
  
  @doc "Invokes the fxg compiler, a la `fxg -`, piping `data` into the process stdin, and reading the stdout. "
  @spec invoke_fxg(binary()) :: binary()
  defp invoke_fxg(data) do
    {:ok, res} = Rambo.run("fxg", ["-"], in: data)
    res.out
  end
end
