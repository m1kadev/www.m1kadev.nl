require Mix
require EEx

Mix.install([
  {:tzdata, "~> 1.1"}
])

Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

defmodule Templates do
  binfo_template = """
  commit=<%= commit %>lightningcss=<%= lightningcss %>html_minifier_next=<%= html_minifier_next %>uglifyjs=<%= uglifyjs %>build_time=<%= build_time %>
  """

  pastelink_template = """
  <a href="/<%= location %>.html"><%= name %></a> | <%= date %>
  """

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

  EEx.function_from_string(
    :def,
    :pastelink,
    pastelink_template,
    [
      :location,
      :name,
      :date
    ]
  )
end

defmodule Builders do
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
    own_template = input_path |> String.replace_suffix("fxg", "html")

    case File.read(own_template) do
      {:ok, ctemplate} -> _fxg(input_path, ctemplate)
      _ -> _fxg(input_path, template)
    end
  end

  def paste(input_path, template) do
    {:ok, rcode} = File.read(input_path)

    output = "build/" <> input_path <> ".html"

    code =
      rcode
      |> String.replace("&", "&amp;")
      |> String.replace("<", "&lt;")
      |> String.replace(">", "&gt;")

    lang = Path.extname(input_path) |> String.slice(1..-1//1)
    file = Path.basename(input_path)
    {:ok, %File.Stat{mtime: mtime}} = File.stat(input_path, time: :posix)

    result =
      template
      |> String.replace("$LANG", lang)
      |> String.replace("$CODE", code)
      |> String.replace("$FILENAME", input_path)
      |> String.replace("$FILEMETA", "Created on " <> Integer.to_string(mtime))

    :ok = File.write(output, result)
  end

  defp _fxg(input_path, template) do
    output_path =
      String.replace_prefix(input_path, "src", "build")
      |> String.replace_suffix("fxg", "html")

    {output, 0} = System.cmd("fxg", [input_path])
    output = String.replace(template, "<content />", output)
    File.write(output_path, output)
  end
end

defmodule FileX do
  def created(path) do
    {:ok, %File.Stat{mtime: {{y, m, d}, _}}} = File.stat(path, time: :local)
    Integer.to_string(d) <> "/" <> Integer.to_string(m) <> "/" <> Integer.to_string(y)
  end
end

{commit, 0} = System.cmd("git", ["rev-parse", "HEAD"])

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

{:ok, main_template} = File.read("src/index.html")

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

File.mkdir_p("build/pastes")

{:ok, paste_template} = File.read("pastes/paste.html")

pastes = Path.wildcard("pastes/**/*")

pastes
|> Task.async_stream(fn file -> Builders.paste(file, paste_template) end)
|> Enum.to_list()

# i cant test this :)) hope it works
paste_data =
  Map.new(pastes, fn x -> {x, FileX.created(x)} end)
  |> Enum.map(fn {x, y} -> Templates.pastelink(x, x, y) end)
  |> Enum.join("<br>")

pastes_header = """
<h1>my pastes</h1>
<p>random code snippets i found useful or wanted to save :))</p>
<hr>
"""

paste_index =
  main_template
  |> String.replace("<content />", pastes_header <> "<p>" <> paste_data <> "</p>")

File.write("build/pastes/index.html", paste_index)

{:ok, date} = DateTime.now("Europe/Amsterdam")
build_time = Calendar.strftime(date, "%H:%M:%S %d/%m/%y")

File.write(
  "build/info.txt",
  Templates.build_info(
    commit,
    lightningcss |> String.split_at(13) |> elem(1),
    html_minifier_next,
    uglifyjs |> String.split_at(10) |> elem(1),
    build_time
  )
)
