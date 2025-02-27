sizes = ~w(10M 100M 1B)
versions = Ibrc.versions() -- ~w(v0 v1)

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
