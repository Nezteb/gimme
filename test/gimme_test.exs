defmodule GimmeTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Gimme

  test "it works" do
    Enum.each(["key", :key], fn key ->
      Enum.each([%{key: true}, %{"key" => true}], fn map ->
        assert Gimme.dat(map, key) == {:ok, true}
        assert Gimme.dat!(map, key) == true
      end)
    end)
  end

  test "false and nil count" do
    for value <- [false, nil], map <- [%{key: value}, %{"key" => value}], key <- [:key, "key"] do
      assert Gimme.dat(map, key) == {:ok, value}
      assert Gimme.dat!(map, key) == value
    end
  end

  property "it finds it no matter how it's stored" do
    check all(
            name <- string(:alphanumeric, min_length: 1),
            value <- term(),
            stored_as <- member_of([:atom, :string]),
            lookup_as <- member_of([:atom, :string])
          ) do
      atom = String.to_atom(name)
      map = if stored_as == :atom, do: %{atom => value}, else: %{name => value}
      key = if lookup_as == :atom, do: atom, else: name

      assert Gimme.dat(map, key) == {:ok, value}
      assert Gimme.dat!(map, key) == value
    end
  end

  property "it doesn't blow up when it's not there" do
    check all(
            name <- string(:alphanumeric, min_length: 1),
            lookup_as <- member_of([:atom, :string]),
            others <- map_of(string(:alphanumeric), term())
          ) do
      # string lookups might not have an atom yet, which used to blow up
      key = if lookup_as == :atom, do: String.to_atom(name), else: name
      map = Map.delete(others, name)

      assert Gimme.dat(map, key) == {:error, :not_found}
      assert_raise KeyError, fn -> Gimme.dat!(map, key) end
    end
  end
end
