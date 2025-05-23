defmodule Ibrc.V2 do
  @compile {:inline, char_to_num: 1, parse_temperature: 1}

  def report(path, chunk_size \\ 100_000) do
    path
    |> read
    |> Stream.chunk_every(chunk_size)
    |> Task.async_stream(fn chunk -> chunk |> parse |> aggregate end)
    |> merge
    |> fmt
  end

  def read(path), do: File.stream!(path, :line)

  def parse(lines) do
    Stream.map(lines, fn line ->
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
  end

  def merge(chunks) do
    Enum.reduce(chunks, %{}, fn {:ok, chunk}, acc ->
      Map.merge(acc, chunk, fn _city, {min1, sum1, count1, max1}, {min2, sum2, count2, max2} ->
        {min(min1, min2), sum1 + sum2, count1 + count2, max(max1, max2)}
      end)
    end)
    |> Enum.sort()
  end

  def fmt(acc) do
    <<?,, ?\s, data::binary>> =
      Enum.reduce(acc, <<>>, fn {city, {min, sum, count, max}}, acc ->
        min = :erlang.float_to_binary(min / 10, decimals: 1)
        mean = :erlang.float_to_binary(sum / (10 * count), [:compact, decimals: 1])
        max = :erlang.float_to_binary(max / 10, decimals: 1)

        <<acc::binary, ?,, ?\s, city::binary, ?=, min::binary, ?/, mean::binary, ?/, max::binary>>
      end)

    "{" <> data <> "}"
  end
end
