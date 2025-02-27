defmodule IbrcTest do
  use ExUnit.Case

  @data "data/wd-1K.txt"

  @tag :tmp_dir
  test "v0 generates valid output", %{tmp_dir: dir} do
    file = Path.join(dir, "data.txt")

    File.write(file, """
    London;10.4
    Tokyo;12.8
    New York City;-4.3
    Tokyo;15.7
    New York City;3.2
    Amsterdam;6.4
    """)

    result =
      "{Amsterdam=6.4/6.4/6.4, London=10.4/10.4/10.4, New York City=-4.3/-0.5/3.2, Tokyo=12.8/14.3/15.7}"

    assert Ibrc.report(:v0, file) == result
  end

  for version <- List.delete(Ibrc.versions(), "v0") do
    v0 = Ibrc.report(:v0, @data)

    test "#{version} coherent with v0" do
      assert Ibrc.report(unquote(version), @data) == unquote(v0)
    end
  end
end
