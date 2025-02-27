sizes = ~w(1K 10K 100K 1M)
versions = Ibrc.versions()

suite =
  versions
  |> Enum.map(fn version -> {version, fn path -> Ibrc.report(version, path) end} end)
  |> :maps.from_list()

inputs =
  sizes |> Enum.map(fn size -> {size, "data/wd-#{size}.txt"} end) |> :maps.from_list()

Benchee.run(suite,
  inputs: inputs,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  profile_after: false
)
