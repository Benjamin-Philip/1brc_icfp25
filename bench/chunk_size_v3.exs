sizes = ~w(1M 10M)

chunk_sizes = [
  {"64 KB", 64 * 1024},
  {"128 KB", 128 * 1024},
  {"256 KB", 256 * 1024},
  {"512 KB", 512 * 1024},
  {"1MB", 1 * 1024 * 1024},
  {"4MB", 4 * 1024 * 1024},
  {"8MB", 8 * 1024 * 1024}
]

suite =
  chunk_sizes
  |> Enum.map(fn {name, size} -> {name, fn path -> Ibrc.V3.report(path, size) end} end)
  |> :maps.from_list()

inputs = sizes |> Enum.map(fn size -> {size, "data/wd-#{size}.txt"} end) |> :maps.from_list()

Benchee.run(suite,
  inputs: inputs,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  profile_after: false,
  time: 20
)
