defmodule GimmeTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest Gimme

  test "it works" do
    for key <- ["key", :key], map <- [%{key: true}, %{"key" => true}] do
      assert Gimme.dat(map, key) == {:ok, true}
      assert Gimme.dat!(map, key) == true
    end
  end

  test "false and nil count" do
    for value <- [false, nil], map <- [%{key: value}, %{"key" => value}], key <- [:key, "key"] do
      assert Gimme.dat(map, key) == {:ok, value}
      assert Gimme.dat!(map, key) == value
    end
  end

  test "nil, true, and false keys don't count" do
    for name <- ["nil", "true", "false"] do
      map = %{String.to_atom(name) => 1}
      assert Gimme.dat(map, name) == {:error, :not_found}
      assert_raise KeyError, fn -> Gimme.dat!(map, name) end
    end
  end

  property "it finds it no matter how it's stored" do
    check all(
            name <- key_name(),
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
            name <- key_name(),
            lookup_as <- member_of([:atom, :string]),
            others <- map_of(one_of([string(:alphanumeric), atom(:alphanumeric)]), term())
          ) do
      atom = String.to_atom(name)
      key = if lookup_as == :atom, do: atom, else: name
      map = Map.drop(others, [name, atom])

      assert Gimme.dat(map, key) == {:error, :not_found}
      assert_raise KeyError, fn -> Gimme.dat!(map, key) end
    end
  end

  defp key_name do
    filter(string(:alphanumeric, min_length: 1), &(&1 not in ["nil", "true", "false"]))
  end
end
