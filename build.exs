require Mix

Mix.install([
  {:tzdata, "~> 1.1"}
])

require EEx

# hello

Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

defmodule Builders do
  binfo_template = """
  commit=<%= commit %>lightningcss=<%= lightningcss %>html_minifer_next=<%= html_minifier_next %>uglifyjs=<%= uglifyjs %>build_time=<%= build_time %>
  """

  def html(input_path) do
    output_path = String.replace_prefix(input_path, "src", "build")

    {_, 0} =
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

    {_, 0} =
      System.cmd("lightningcss", [
        "-m",
        "-o",
        output_path,
        input_path
      ])
  end

  def js(input_path) do
    output_path = String.replace_prefix(input_path, "src", "build")

    {_, 0} =
      System.cmd("uglifyjs", [
        "-c",
        "-o",
        output_path,
        input_path
      ])
  end

  def fxg(input_path, template) do
    output_path =
      String.replace_prefix(input_path, "src", "build")
      |> String.replace_suffix("fxg", "html")

    {output, 0} = System.cmd("fxg", [input_path])
    output = String.replace(template, "<fxg-content />", output)
    File.write(output_path, output)
  end

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

{commit, 0} = System.cmd("lightningcss", ["-V"])

{lightningcss, 0} = System.cmd("lightningcss", ["-V"])

{html_minifier_next, 0} = System.cmd("html-minifier-next", ["-V"])

{uglifyjs, 0} = System.cmd("uglifyjs", ["-V"])

File.rm_rf("build")

case File.mkdir_p("build/static") do
  :ok -> {}
  _ -> raise "Couldn't create the build file structure (/build/static)"
end

# Path.wildcard("src/**/*.html")
# |> Task.async_stream(fn file -> Builders.html(file) end)
# |> Enum.to_list()

{:ok, main_template} = File.read("src/template.html")

Path.wildcard("src/**/*.css")
|> Task.async_stream(fn file -> Builders.css(file) end)
|> Enum.to_list()

Path.wildcard("src/**/*.js")
|> Task.async_stream(fn file -> Builders.js(file) end)
|> Enum.to_list()

Path.wildcard("src/**/*.fxg")
|> Task.async_stream(fn file -> Builders.fxg(file, main_template) end)
|> Enum.to_list()

Path.wildcard("static/**/*")
|> Task.async_stream(fn file -> File.cp(file, "build/" <> file) end)
|> Enum.to_list()

{:ok, date} = DateTime.now("Europe/Amsterdam")
build_time = Calendar.strftime(date, "%H:%M:%S %d/%m/%y")

File.write(
  "build/info.txt",
  Builders.build_info(commit, lightningcss, html_minifier_next, uglifyjs, build_time)
)
