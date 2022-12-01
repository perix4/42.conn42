defmodule Conn42Test do
  use ExUnit.Case
  doctest Conn42

  test "greets the world" do
    assert Conn42.hello() == :world
  end
end
