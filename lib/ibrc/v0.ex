defmodule Ibrc.V0 do
  def report(path) do
    path
    |> read
    |> parse
    |> aggregate
    |> fmt
  end

  def read(path), do: File.read!(path) |> String.split("\n", trim: true)

  def parse(lines) do
    Enum.map(lines, fn line ->
      [city, temp] = String.split(line, ";")
      {city, String.to_float(temp)}
    end)
  end

  def aggregate(readings) do
    Enum.reduce(readings, %{}, fn {city, temp}, acc ->
      Map.update(acc, city, {temp, temp, 1, temp}, fn
        {min, sum, count, max} -> {min(min, temp), sum + temp, count + 1, max(max, temp)}
      end)
    end)
  end

  def fmt(acc) do
    data =
      acc
      |> Enum.sort()
      |> Enum.map(fn {city, {min, sum, count, max}} ->
        "#{city}=#{min}/#{Float.round(sum / count, 1)}/#{max}"
      end)
      |> Enum.join(", ")

    "{" <> data <> "}"
  end
end
