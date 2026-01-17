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

  @spec collect(binary(), %{binary() => binary()}) :: %{}
  def collect(project_root, bricks) do
    %Thoughts{
      thoughts:
        Path.wildcard("#{project_root}/thoughts/*")
        |> Enum.map(fn path -> {path, File.read!(path)} end),
      template: File.read!("#{project_root}/templates/thought.thtml"),
      bricks: bricks,
      project_root: project_root
    }
  end

  @spec ensure_folders(binary()) :: :ok
  def ensure_folders(project_root) do
    File.mkdir_p!("#{project_root}/build/thoughts/")
  end

  @spec compile(%Thoughts{}) :: :ok
  def compile(thoughts) do
    ensure_folders(thoughts.project_root)

    thoughts.thoughts
    |> Task.async_stream(fn thought ->
      compile_file(thought, thoughts.template, thoughts.bricks, thoughts.project_root)
    end)
    |> Enum.to_list()
  end

  defp compile_file({path, thought}, template, bricks, project_root) do
    name = trim_abs_path(path, project_root)
    # unix timestamp
    date = get_file_commit_date(path)
    output_path = "#{project_root}/build/thoughts/#{urlify(name)}.html"
    mustache_context = Map.merge(bricks, %{thought: thought, name: name, date: date})

    File.write!(output_path, Mustache.render(template, mustache_context))
    IO.puts("[COMPILED] #{path} -> #{output_path}")
  end

  def get_file_commit_date(path) do
    {ts_string, 0} = System.cmd("git", ["log", "--format=%ct", path])

    time =
      String.to_integer(String.trim_trailing(ts_string))
      |> DateTime.from_unix!()
      |> Calendar.strftime("%d/%m/%y (%H:%M)")
  end
end
