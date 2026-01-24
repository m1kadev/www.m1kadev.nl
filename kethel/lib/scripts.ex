require Rambo

defmodule Scripts do
  defstruct [:scripts, :project_root]

  defp ensure_file_structure(project_root) do
    File.mkdir_p!("#{project_root}/build/scripts")
  end

  defp trim_abs_path(path, project_root) do
    # ROOT + scripts/
    begin = byte_size(project_root) + byte_size("scripts/")
    # remove extension
    binary_part(path, begin, byte_size(path) - begin)
  end

  def collect(project_root) do
    %Scripts{
      scripts:
        Path.wildcard(project_root <> "/scripts/**/*.js")
        |> Task.async_stream(fn script ->
          {trim_abs_path(script, project_root), File.read!(script)}
        end)
        |> Enum.map(fn {:ok, val} -> val end),
      project_root: project_root
    }
  end

  def compile(scripts) do
    t_begin = System.monotonic_time(:millisecond)

    ensure_file_structure(scripts.project_root)

    scripts.scripts
    |> Task.async_stream(fn script -> compile_file(script, scripts.project_root) end)
    |> Enum.map(fn {:ok, val} -> val end)

    t_end = System.monotonic_time(:millisecond)
    t_end - t_begin
  end

  # data | npx lightningcss -m
  defp compile_file({path, data}, project_root) do
    {:ok, %Rambo{out: out}} = Rambo.run("npx", ["uglifyjs"], in: data)
    output_path = "#{project_root}/build/scripts#{path}"
    File.write!(output_path, out)

    IO.puts("[COMPILED] #{project_root}/scripts#{path} -> #{output_path}")
  end
end
