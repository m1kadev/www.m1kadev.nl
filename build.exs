defmodule Builders do
  def html(input_path) do
    output_path = String.replace_prefix(input_path, "src", "build")

    System.cmd("html-minifier-next", [
      "--preset",
      "comprehensive",
      "-o",
      output_path,
      input_path
    ])
  end

  def css(input_path) do
    output_path = String.replace_prefix(input_path, "src", "build")

    System.cmd("lightningcss", [
      "-m",
      "-o",
      output_path,
      input_path
    ])
  end

  # TODO: js support :)
end

File.rm_rf("build")

case File.mkdir("build") do
  :ok -> {}
  _ -> raise "Couldn't create build folder"
end

case File.mkdir("build/static") do
  :ok -> {}
  _ -> raise "Couldn't create build/static folder"
end

Path.wildcard("src/**/*.html")
|> Task.async_stream(fn file -> Builders.html(file) end)
|> Enum.to_list()

Path.wildcard("src/**/*.css")
|> Task.async_stream(fn file -> Builders.css(file) end)
|> Enum.to_list()

Path.wildcard("static/**/*")
|> Task.async_stream(fn file -> File.cp(file, "build/" <> file) end)
|> Enum.to_list()
