defmodule Ibrc do
  @versions ~w(v0 v1)

  def versions(), do: @versions

  for version <- @versions do
    mod = Module.concat([:Ibrc, String.upcase(version)])

    def report(unquote(version), file), do: apply(unquote(mod), :report, [file])
    def report(unquote(String.to_atom(version)), file), do: apply(unquote(mod), :report, [file])
  end
end
