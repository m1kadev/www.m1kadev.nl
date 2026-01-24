defmodule Thoughts do
  defstruct [:thoughts, :template, :bricks, :project_root]

  @spec urlify(binary()) :: binary()
  defp urlify(name) do
    name
    |> String.replace(" ", "_")
  end

  @spec trim_abs_path(binary(), binary()) :: binary()
  defp trim_abs_path(path, project_root) do
    # ROOT + thoughts/
    begin = byte_size(project_root) + byte_size("/thoughts/")
    binary_part(path, begin, byte_size(path) - begin)
  end

  @spec collect(binary(), %{binary() => binary()}) :: %Thoughts{}
  def collect(project_root, bricks) do
    %Thoughts{
      thoughts:
        Path.wildcard("#{project_root}/thoughts/*")
        |> Enum.map(fn path -> {path, get_file_commit_date(path), File.read!(path)} end)
        |> Enum.sort_by(fn {_, date, _ } -> date end, :desc),
      template: File.read!("#{project_root}/templates/thought.thtml"),
      bricks: bricks,
      project_root: project_root
    }
  end

  @spec ensure_folders(binary()) :: :ok
  def ensure_folders(project_root) do
    File.mkdir_p!("#{project_root}/build/thoughts/")
  end

  @spec compile(%Thoughts{}) :: pos_integer()
  def compile(thoughts) do
    t_begin = System.monotonic_time(:millisecond)
    ensure_folders(thoughts.project_root)

    thoughts.thoughts
    |> Task.async_stream(fn thought ->
      compile_file(thought, thoughts.template, thoughts.bricks, thoughts.project_root) end)
    |> Enum.to_list()

    t_end = System.monotonic_time(:millisecond)

    t_end - t_begin
  end

  defp compile_file({path, date, thought}, template, bricks, project_root) do
    name = trim_abs_path(path, project_root)
    output_path = "#{project_root}/build/thoughts/#{urlify(name)}.html"
    mustache_context = Map.merge(bricks, %{thought: thought, name: name, date: date})

    File.write!(output_path, Mustache.render(template, mustache_context))
    IO.puts("[COMPILED] #{path} -> #{output_path}")
  end

  def get_file_commit_date(path) do
    {ts_string, 0} = System.cmd("git", ["log", "--format=%ct", path])
    
    String.trim_trailing(ts_string)
      |> String.to_integer()
  end

  def to_rss({path, date, thought}, template, project_root) do
    location = String.replace_prefix(path, project_root <> "/thoughts/", "")
    link = "https://m1kadev.nl/thoughts/" <> urlify(location) <> ".html"
    rfc_date = date
    |> DateTime.from_unix!()
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S %Z")
    Mustache.render(template, %{title: location, date: rfc_date, description: thought, category: "thoughts", link: link } ) 
  end
end
