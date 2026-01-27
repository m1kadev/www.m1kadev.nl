args = System.argv()

folder = Enum.at(args, 1)

if folder != nil do
  project_root = Path.expand(folder)

  File.rm_rf!("#{project_root}/build")
  File.mkdir_p("#{project_root}/build")

  collection_time_start = System.monotonic_time(:millisecond)

  # other contents depend on this, so we cant async it
  bricks = Bricks.collect(project_root)

  # special case, see module documentation
  statics_task = Task.async(fn -> Statics.compile(project_root) end)

  styles_task = Task.async(fn -> Styles.collect(project_root) end)
  scripts_task = Task.async(fn -> Scripts.collect(project_root) end)
  pages_task = Task.async(fn -> Pages.collect(project_root, bricks) end)
  thoughts_task = Task.async(fn -> Thoughts.collect(project_root, bricks) end)

  [styles, pages, scripts, thoughts] =
    Task.await_many([styles_task, pages_task, scripts_task, thoughts_task], :infinity)

  collection_time_end = System.monotonic_time(:millisecond)

  compilation_time_start = System.monotonic_time(:millisecond)
  
  pages_compile_task = Task.async(fn -> Pages.compile(pages) end)
  styles_compile_task = Task.async(fn -> Styles.compile(styles) end)
  scripts_compile_task = Task.async(fn -> Scripts.compile(scripts) end)
  thoughts_compile_task = Task.async(fn -> Thoughts.compile(thoughts) end)

  [ pages_time, styles_time, scripts_time, thoughts_time] = Task.await_many(
    [
      pages_compile_task,
      styles_compile_task,
      scripts_compile_task,
      thoughts_compile_task
    ],
    :infinity
  )

  compilation_time_end = System.monotonic_time(:millisecond)

  rss_header = File.read!("#{project_root}/rss/feed.txml")
  rss_footer = "</channel></rss>"
  rss_item_template = File.read!("#{project_root}/rss/item.txml")

  rss_thoughts = thoughts.thoughts
    |> Enum.take(10)
    |> Enum.map(fn thought -> Thoughts.to_rss(thought, rss_item_template, project_root) end)
    |> Enum.join();

  File.write!("#{project_root}/build/rss.xml", rss_header <> rss_thoughts <> rss_footer)

  IO.puts("[COMPILED] #{project_root}/build/rss.xml")
  
  { lcss_version, 0 }= System.cmd("npx", [ "lightningcss", "-V" ])
  { hmn_version, 0 } = System.cmd("npx", [ "html-minifier-next", "-V" ])
  { ujs_version, 0 } = System.cmd("npx", [ "uglifyjs", "-V" ])
  { git_commit, 0 } = System.cmd("git", [ "rev-parse", "HEAD" ])

  { build_date, 0 } = System.cmd("date", ["+%H:%M %d/%m/%y"])

  info_txt = """
  commit=#{git_commit}
  lightningcss=#{lcss_version}
  html_minifier_next=#{hmn_version}
  uglifyjs=#{ujs_version}
  build_time=#{build_date}
  """
  
  File.write!("#{project_root}/build/info.txt", info_txt)

  IO.puts("[COMPILED] #{project_root}/build/info.txt")

  IO.puts("Finalising...");

  File.cp!("#{project_root}/favicon.ico", "#{project_root}/build/favicon.ico")
  IO.puts("")
  IO.puts(:stderr, "===== BUILD RESULTS =====")
  IO.puts(:stderr, "FILE READING (*.collect()) | #{collection_time_end - collection_time_start}ms") 
  IO.puts(:stderr, "Root page (compile)        | #{pages_time}ms")
  IO.puts(:stderr, "Styles (compile)           | #{styles_time}ms")
  IO.puts(:stderr, "Scripts (compile)          | #{scripts_time}ms")
  IO.puts(:stderr, "Thoughts (compile)         | #{thoughts_time}ms")
else
  IO.puts(:stderr, "The root project folder should be provided on the command line")
end
