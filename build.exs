require EEx
require Tzdata

Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

defmodule Builders do
  binfo_template = """
  commit=<%= commit %>
  lightningcss=<%= lightningcss %>
  html_minifer_next=<%= html_minifier_next %>
  uglifyjs=<%= uglifyjs %>
  build_time=<%= build_time %>
  """

  def html(input_path) do
    output_path = String.replace_prefix(input_path, "src", "build")

    System.cmd("html-minifier-next", [
      "--preset",
      "conservative",
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

  def js(input_path) do
    output_path = String.replace_prefix(input_path, "src", "build")

    System.cmd("uglifyjs", [
      "-c",
      "-o",
      output_path,
      input_path
    ])
  end

  # TODO: js support :)

  EEx.function_from_string(
    :def,
    :build_info,
    binfo_template,
    [
      :commit,
      :lightningcss,
      :html_minifier_next,
      :uglifyjs,
      :build_time
    ]
  )
end

commit =
  System.cmd("git", ["rev-parse", "HEAD"])
  |> elem(0)
  |> String.trim()

lightningcss =
  System.cmd("lightningcss", ["-V"])
  |> elem(0)
  |> String.trim()

html_minifier_next =
  System.cmd("html-minifier-next", ["-V"])
  |> elem(0)
  |> String.trim()

uglifyjs =
  System.cmd("uglifyjs", ["-V"])
  |> elem(0)
  |> String.trim()

File.rm_rf("build")

case File.mkdir_p("build/static") do
  :ok -> {}
  _ -> raise "Couldn't create the build file structure (/build/static)"
end

Path.wildcard("src/**/*.html")
|> Task.async_stream(fn file -> Builders.html(file) end)
|> Enum.to_list()

Path.wildcard("src/**/*.css")
|> Task.async_stream(fn file -> Builders.css(file) end)
|> Enum.to_list()

Path.wildcard("src/**/*.js")
|> Task.async_stream(fn file -> Builders.js(file) end)
|> Enum.to_list()

Path.wildcard("static/**/*")
|> Task.async_stream(fn file -> File.cp(file, "build/" <> file) end)
|> Enum.to_list()

build_time =
  DateTime.now("Europe/Amsterdam")
  |> elem(1)
  |> Calendar.strftime("%H:%M:%S %d/%m/%y")

File.write(
  "build/info.txt",
  Builders.build_info(commit, lightningcss, html_minifier_next, uglifyjs, build_time)
)
