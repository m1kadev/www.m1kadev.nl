require Mix
require EEx

Mix.install([
  {:tzdata, "~> 1.1"},
  {:mustache, "~> 0.5.0"}
])

Calendar.put_time_zone_database(Tzdata.TimeZoneDatabase)

defmodule Git do
  def get_file_commit(path) do
    {ts_string, 0} = System.cmd("git", ["log", "--format=%ct", path])
    String.to_integer(String.trim_trailing(ts_string))
  end
end

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

  def ogp(title, url, description) do
    """
      <meta property="og:type" content="website">
      <meta property="og:title" content="#{title}">
      <meta property="og:url" content="#{url}">
      <meta property="og:image" content="https://m1kadev.nl/static/logo.png">
      <meta property="og:description" content="#{description}">
      <meta property="og:locale" content="en_GB" />
      <meta property="og:site_name" content="m1kadev.nl" />
    """
  end
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
    output_path = "build/" <> input_path

    {_, 0} =
      System.cmd("lightningcss", [
        "-m",
        "-o",
        output_path,
        input_path
      ])
  end

  def js(input_path) do
    output_path = "build/" <> input_path

    {_, 0} =
      System.cmd("uglifyjs", [
        "-c",
        "-o",
        output_path,
        input_path
      ])
  end

  def fxg(input_path, template, bricks) do
    own_template =
      input_path
      |> String.replace_prefix("pages", "templates/pages")
      |> String.replace_suffix("fxg", "html")

    case File.read(own_template) do
      {:ok, ctemplate} -> _fxg(input_path, ctemplate, bricks)
      _ -> _fxg(input_path, template, bricks)
    end
  end

  def paste(input_path, template, bricks) do
    {:ok, code} = File.read(input_path)
    IO.inspect(code)

    output = "build/" <> input_path <> ".html"

    lang = Path.extname(input_path) |> String.slice(1..-1//1)
    file = Path.basename(input_path)
    time = FileX.createdf(input_path)

    result =
      Mustache.render(
        template,
        Map.merge(
          %{
            filename: file,
            about_paste: "Created on " <> time,
            language: "<script src=\"static/" <> lang <> ".min.js\"></script>",
            codetag: "<pre><code class=\"language-" <> lang <> "\">",
            code: code,
            ogp:
              Templates.ogp(file, "https://m1kadev.nl/pastes/#{file}.html", "Created on " <> time)
          },
          bricks
        )
      )

    IO.inspect(input_path)

    :ok = File.write(output, result)
  end

  defp _fxg(input_path, template, bricks) do
    output_path =
      String.replace_prefix(input_path, "pages", "build")
      |> String.replace_suffix("fxg", "html")

    name =
      case Path.basename(input_path) |> Path.rootname() do
        "index" -> "home"
        x -> x
      end

    {content, 0} = System.cmd("fxg", [input_path])

    ogp =
      Templates.ogp(
        name,
        "https://m1kadev.nl/#{String.replace_prefix(output_path, "build/", "")}",
        ""
      )

    output =
      Mustache.render(
        template,
        Map.merge(
          %{
            fxg_content: content,
            location: name,
            ogp: ogp
          },
          bricks
        )
      )

    IO.inspect(output_path)
    :ok = File.write(output_path, output)
  end

  def thought(path, unix) do
    thought = File.read!(path)
    name = String.replace_prefix(path, "thoughts/", "")

    date = DateTime.from_unix!(unix) |> Calendar.strftime("%d/%m/%y (%H:%M)")

    """
    <div class="thought">
    <h3><a href="/thoughts/#{FileX.sanitised_name(name)}.html">#{name}</a></h3>
    <span>#{thought}</span>
    <small> -mika, #{date}</small>
    </div>
    """
  end
end

defmodule FileX do
  def createdf(path) do
    {:ok, %File.Stat{mtime: {{y, m, d}, _}}} = File.stat(path, time: :local)
    "#{d}/#{m}/#{y}"
  end

  def created(path) do
    {:ok, %File.Stat{mtime: x}} = File.stat(path, time: :posix)
    x
  end

  def sanitised_name(path) do
    Path.basename(path)
    |> String.trim_trailing(".html")
    |> String.replace("-", "_")
    |> String.replace(" ", "_")
  end
end

{commit, 0} = System.cmd("git", ["rev-parse", "HEAD"])

{lightningcss, 0} = System.cmd("lightningcss", ["-V"])

{html_minifier_next, 0} = System.cmd("html-minifier-next", ["-V"])

{uglifyjs, 0} = System.cmd("uglifyjs", ["-V"])

File.rm_rf("build")

File.mkdir_p!("build")

bricks =
  Path.wildcard("bricks/*.html")
  |> Map.new(fn x -> {FileX.sanitised_name(x), File.read!(x)} end)

{:ok, main_template} = File.read("templates/base.html")

Path.wildcard("pages/**/*.fxg")
|> Task.async_stream(fn file -> Builders.fxg(file, main_template, bricks) end)
|> Enum.to_list()

File.mkdir_p!("build/static")

Path.wildcard("static/**/*")
|> Task.async_stream(fn file -> File.cp(file, "build/" <> file) end)
|> Enum.to_list()

File.mkdir_p!("build/scripts")

Path.wildcard("scripts/**/*.js")
|> Task.async_stream(fn file -> Builders.js(file) end)
|> Enum.to_list()

File.mkdir_p!("build/styles")

Path.wildcard("styles/**/*.css")
|> Task.async_stream(fn file -> Builders.css(file) end)
|> Enum.to_list()

File.mkdir_p("build/pastes")

{:ok, paste_template} = File.read("templates/paste.html")

pastes =
  Path.wildcard("pastes/**/*")
  |> Enum.map(fn path -> {path, Git.get_file_commit(path)} end)
  |> Enum.sort_by(fn {_, t} -> t end, :desc)
  |> Enum.map(fn {path, _} -> path end)

pastes
|> Task.async_stream(fn file -> Builders.paste(file, paste_template, bricks) end)
|> Enum.to_list()

paste_data =
  Map.new(pastes, fn x -> {x, FileX.createdf(x)} end)
  |> Enum.map(fn {x, y} -> Templates.pastelink(x, x, y) end)
  |> Enum.join("<br>")

pastes_header = """
<h1>my pastes</h1>
<p>random code snippets i found useful or wanted to save :))</p>
<hr>
"""

# main_template
# |> String.replace("<content />", pastes_header <> "<p>" <> paste_data <> "</p>")
paste_index =
  Mustache.render(
    main_template,
    Map.merge(bricks, %{
      fxg_content: pastes_header <> "<p>" <> paste_data <> "</p>",
      location: "pastes",
      ogp:
        Templates.ogp(
          "thoughts",
          "https://m1kadev.nl/pastes",
          "random code snippets i found useful or wanted to save :))"
        )
    })
  )

File.write("build/pastes/index.html", paste_index)

File.mkdir_p("build/thoughts")

thoughts_template = File.read!("templates/thoughts.html")
thought_template = File.read!("templates/thought.html")

thought_paths =
  Path.wildcard("thoughts/**/*")
  |> Enum.map(fn path -> {path, Git.get_file_commit(path)} end)
  |> Enum.sort_by(fn {_, t} -> t end, :desc)

thoughts = Enum.map(thought_paths, fn {path, date} -> Builders.thought(path, date) end)

thoughts_html =
  Mustache.render(
    thoughts_template,
    Map.merge(bricks, %{
      fxg_content: Enum.join(thoughts, "<hr>"),
      location: "thoughts",
      ogp:
        Templates.ogp(
          "thoughts",
          "https://m1kadev.nl/thoughts",
          "important thoughts that needed publishing"
        )
    })
  )

for {thought, {path, time}} <- Enum.zip(thoughts, thought_paths) do
  thought = FileX.sanitised_name(path)
  output_path = "build/thoughts/" <> thought <> ".html"

  when_said = DateTime.from_unix!(time) |> Calendar.strftime("%H:%M, %d/%m/%y")
  thought_txt = File.read!(path)

  thought_html =
    Mustache.render(
      thought_template,
      Map.merge(bricks, %{
        fxg_content: thought_txt,
        thought: thought,
        date: when_said,
        ogp:
          Templates.ogp(
            thought,
            "https://m1kadev.nl/#{String.replace_prefix(output_path, "build/", "")}",
            String.replace(thought_txt, "\"", "&qout;")
          )
      })
    )

  File.write(output_path, thought_html)
end

File.write("build/thoughts/index.html", thoughts_html)

File.copy("favicon.ico", "build/favicon.ico")

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
