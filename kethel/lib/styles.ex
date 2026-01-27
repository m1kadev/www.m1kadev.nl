require Rambo

defmodule Styles do
  defstruct [:styles, :project_root]

  defp ensure_file_structure(project_root) do
    File.mkdir_p!("#{project_root}/build/styles")
  end

  defp trim_abs_path(path, project_root) do
    # ROOT + styles/
    begin = byte_size(project_root) + byte_size("styles/")
    # remove extension
    binary_part(path, begin, byte_size(path) - begin)
  end

  def collect(project_root) do
    %Styles{
      styles:
        Path.wildcard(project_root <> "/styles/**/*.css")
        |> Task.async_stream(fn style ->
          {trim_abs_path(style, project_root), File.read!(style)}
        end)
        |> Enum.map(fn {:ok, val} -> val end),
      project_root: project_root
    }
  end

  def compile(styles) do
    t_begin = System.monotonic_time(:millisecond)

    ensure_file_structure(styles.project_root)

    styles.styles
    |> Task.async_stream(fn style -> compile_file(style, styles.project_root) end)
    |> Enum.map(fn {:ok, val} -> val end)

    t_end = System.monotonic_time(:millisecond)
    t_end - t_begin
  end

  # data | npx lightningcss -m
  defp compile_file({path, data}, project_root) do
    {:ok, %Rambo{out: out}} = Rambo.run("npx", ["lightningcss", "-m"], in: data)
    output_path = "#{project_root}/build/styles#{path}"
    File.write!(output_path, out)

    IO.puts("[COMPILED] #{project_root}/styles#{path} -> #{output_path}")
  end
end
