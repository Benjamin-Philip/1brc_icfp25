defmodule Ibrc.WeatherDataTest do
  use ExUnit.Case

  alias Ibrc.WeatherData, as: WD

  @tag :tmp_dir
  test "async_stream/2 streams to file", %{tmp_dir: dir} do
    file = Path.join(dir, "1K.txt")
    WD.async_stream(dir, "1K")

    assert File.exists?(file)
    assert length(Enum.to_list(File.stream!(file))) == 1000
  end

  test "async_generate/1 generates enough lines" do
    WD.setup()

    lines = WD.async_generate(10) |> Enum.join() |> String.split("\n") |> length()
    assert lines - 1 == 10
  end

  test "line/0 formats a line correctly" do
    WD.setup()

    assert [_city, temp] = WD.line() |> String.trim() |> String.split(";")

    temperature = String.to_float(temp)
    assert Float.round(temperature, 1) == temperature
  end
end
