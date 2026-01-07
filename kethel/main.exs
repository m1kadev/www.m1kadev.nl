args = System.argv()

folder = Enum.at(args, 1)

if folder != nil do
  IO.inspect(folder)
  bricks = Bricks.collect(folder)
  IO.inspect(bricks)
else
  IO.puts(:stderr, "The root project folder should be provided on the command line")
end
