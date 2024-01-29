defmodule AlipayTest do
  use ExUnit.Case
  doctest Alipay

  test "greets the world" do
    assert Alipay.hello() == :world
  end
end
