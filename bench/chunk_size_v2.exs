sizes = ~w(1M 10M)
chunk_sizes = [{"1K", 1_000}, {"10K", 10_000}, {"100K", 100_000}, {"1M", 1_000_000}]

suite =
  chunk_sizes
  |> Enum.map(fn {name, size} -> {name, fn path -> Ibrc.V2.report(path, size) end} end)
  |> :maps.from_list()

inputs = sizes |> Enum.map(fn size -> {size, "data/wd-#{size}.txt"} end) |> :maps.from_list()

Benchee.run(suite,
  inputs: inputs,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  profile_after: false,
  time: 20
)
