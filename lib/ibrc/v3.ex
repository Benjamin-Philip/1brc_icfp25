defmodule Ibrc.V3 do
  @compile {:inline, char_to_num: 1, parse_temperature: 1}

  def report(path, chunk_size \\ 128 * 1024) do
    {:ok, fd} = :prim_file.open(path, [:read, :binary])

    result =
      fd
      |> chunk(chunk_size)
      |> Task.async_stream(fn chunk -> read(fd, chunk) |> parse |> aggregate end,
        max_concurrency: System.schedulers_online() * 10
      )
      |> merge
      |> fmt

    :prim_file.close(fd)

    result
  end

  def chunk(fd, chunk_size) do
    {:ok, size} = :prim_file.position(fd, :eof)
    chunk_recur(fd, size, chunk_size, 0)
  end

  def chunk_recur(_fd, size, chunk_size, pos) when pos + chunk_size >= size,
    do: [{pos, size - pos}]

  def chunk_recur(fd, size, chunk_size, pos) do
    :prim_file.position(fd, pos + chunk_size)
    {:ok, line} = :prim_file.read_line(fd)
    offset = chunk_size + byte_size(line)
    [{pos, offset} | chunk_recur(fd, size, chunk_size, pos + offset)]
  end

  def read(fd, {pos, num}) do
    {atom1, atom2, data} = fd
    fd = {atom1, atom2, %{data | owner: self()}}

    case :prim_file.pread(fd, pos, num) do
      {:ok, bin} -> bin
      {:error, :einval} -> read(fd, {pos, num})
    end
  end

  def parse(bin) do
    Stream.unfold(bin, fn
      <<>> -> nil
      bin -> chunk_line(bin, bin, 0)
    end)
  end

  defp chunk_line(bin, <<?;, _rest::binary>>, count) do
    <<city::binary-size(count), ?;, rest::binary>> = bin
    {temp, rest} = parse_temperature(rest)
    {{city, temp}, rest}
  end

  defp chunk_line(bin, <<_c, rest::binary>>, count) do
    chunk_line(bin, rest, count + 1)
  end

  # ex: -4.5
  defp parse_temperature(<<?-, d1, ?., d2, "\n", rest::binary>>) do
    {-(char_to_num(d1) * 10 + char_to_num(d2)), rest}
  end

  # ex: 4.5
  defp parse_temperature(<<d1, ?., d2, "\n", rest::binary>>) do
    {char_to_num(d1) * 10 + char_to_num(d2), rest}
  end

  # ex: -45.3
  defp parse_temperature(<<?-, d1, d2, ?., d3, "\n", rest::binary>>) do
    {-(char_to_num(d1) * 100 + char_to_num(d2) * 10 + char_to_num(d3)), rest}
  end

  # ex: 45.3
  defp parse_temperature(<<d1, d2, ?., d3, "\n", rest::binary>>) do
    {char_to_num(d1) * 100 + char_to_num(d2) * 10 + char_to_num(d3), rest}
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
        mean = :erlang.float_to_binary(sum / (10 * count), decimals: 1)
        max = :erlang.float_to_binary(max / 10, decimals: 1)

        <<acc::binary, ?,, ?\s, city::binary, ?=, min::binary, ?/, mean::binary, ?/, max::binary>>
      end)

    "{" <> data <> "}"
  end
end
