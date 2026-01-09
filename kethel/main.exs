args = System.argv()

folder = Enum.at(args, 1)

if folder != nil do
  project_root = Path.expand(folder) 
  context = %{
   project_root: project_root,
   bricks: Bricks.collect(project_root)
  }
  pages = Pages.collect(context)
else
  IO.puts(:stderr, "The root project folder should be provided on the command line")
end
