args = System.argv()

folder = Enum.at(args, 1)

if folder != nil do
  project_root = Path.expand(folder)

  File.rm_rf!("#{project_root}/build")
  File.mkdir_p("#{project_root}/build")

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

  pages_compile_task = Task.async(fn -> Pages.compile(pages) end)
  styles_compile_task = Task.async(fn -> Styles.compile(styles) end)
  scripts_compile_task = Task.async(fn -> Scripts.compile(scripts) end)
  thoughts_compile_task = Task.async(fn -> Thoughts.compile(thoughts) end)

  Task.await_many(
    [
      pages_compile_task,
      styles_compile_task,
      statics_task,
      scripts_compile_task,
      thoughts_compile_task
    ],
    :infinity
  )
else
  IO.puts(:stderr, "The root project folder should be provided on the command line")
end
