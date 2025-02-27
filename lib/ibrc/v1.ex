defmodule Ibrc.V1 do
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
      [city, temp] = :binary.split(line, ";")
      {city, parse_temperature(temp)}
    end)
  end

  defp parse_temperature(<<?-, d1, ?., d2, _::binary>>) do
    -(char_to_num(d1) * 10 + char_to_num(d2))
  end

  # ex: 4.5
  defp parse_temperature(<<d1, ?., d2, _::binary>>) do
    char_to_num(d1) * 10 + char_to_num(d2)
  end

  # ex: -45.3
  defp parse_temperature(<<?-, d1, d2, ?., d3, _::binary>>) do
    -(char_to_num(d1) * 100 + char_to_num(d2) * 10 + char_to_num(d3))
  end

  # ex: 45.3
  defp parse_temperature(<<d1, d2, ?., d3, _::binary>>) do
    char_to_num(d1) * 100 + char_to_num(d2) * 10 + char_to_num(d3)
  end

  defp char_to_num(char) do
    char - ?0
  end

  def aggregate(readings) do
    Enum.reduce(readings, %{}, fn {city, temp}, acc ->
      Map.update(acc, city, {temp, temp, 1, temp}, fn
        {min, sum, count, max} -> {min(min, temp), sum + temp, count + 1, max(max, temp)}
      end)
    end)
    |> Enum.sort()
  end

  def fmt(acc) do
    <<?,, ?\s, data::binary>> =
      Enum.reduce(acc, <<>>, fn {city, {min, sum, count, max}}, acc ->
        min = :erlang.float_to_binary(min / 10, decimals: 1)
        mean = :erlang.float_to_binary(sum / (count * 10), [:compact, decimals: 1])
        max = :erlang.float_to_binary(max / 10, decimals: 1)

        <<acc::binary, ?,, ?\s, city::binary, ?=, min::binary, ?/, mean::binary, ?/, max::binary>>
      end)

    "{" <> data <> "}"
  end
end
