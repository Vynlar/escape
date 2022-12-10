defmodule EscapeTest do
  use ExUnit.Case
  doctest Escape

  test "greets the world" do
    assert Escape.hello() == :world
  end
end
