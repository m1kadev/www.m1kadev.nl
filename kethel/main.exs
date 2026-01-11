args = System.argv()

folder = Enum.at(args, 1)

if folder != nil do
  project_root = Path.expand(folder) 
  context = %Context{
    project_root: project_root,
    bricks: Bricks.collect(project_root),
    fxg: System.find_executable("fxg")
  }
  
  File.rm_rf!("#{project_root}/build")
  File.mkdir_p("#{project_root}/build")

  pages = Pages.collect(context)

  Pages.compile(pages)
else
  IO.puts(:stderr, "The root project folder should be provided on the command line")
end
