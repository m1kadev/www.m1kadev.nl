defmodule Statics do
  @moduledoc """
    Statics is an exception, because we only copy the files. Therefore, the performance gain from reading files into memory for processing isn't worth it. The compile fuction gets called at load-time for all other asset types.
  """

  @spec ensure_file_structure(binary()) :: :ok
  defp ensure_file_structure(project_root) do
    File.mkdir_p!("#{project_root}/build/static/")
  end

  defp trim_abs_path(path, project_root) do
    # ROOT + static
    begin = byte_size(project_root) + byte_size("static/")
    # remove extension
    binary_part(path, begin, byte_size(path) - begin)
  end

  # we dont async_stream here because copying is (relatively speaking) inexpensive, and we want to keep more threads open for other (more expensive) compilation processes
  def compile(project_root) do
    ensure_file_structure(project_root)

    for path <- Path.wildcard("#{project_root}/static/**/*") do
      rel_path = trim_abs_path(path, project_root)
      output_path = "#{project_root}/build/static#{rel_path}"

      File.copy!(path, output_path)

      IO.puts("[ COPIED ] #{path} -> #{output_path}")
    end
  end
end
