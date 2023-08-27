defmodule RandomWalkerTest do
  use ExUnit.Case
  doctest RandomWalker

  test "greets the world" do
    assert RandomWalker.hello() == :world
  end
end
