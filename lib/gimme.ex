defmodule Gimme do
  @moduledoc """
  Need to ship a feature but yo data is wack? Use `Gimme.dat(map, :key)`!
  """

  @doc """
  Get any `:key` or `"key"` from a map :)

      iex> Gimme.dat(%{"key" => 1}, :key)
      {:ok, 1}

      iex> Gimme.dat(%{key: false}, "key")
      {:ok, false}

      iex> Gimme.dat(%{}, :key)
      {:error, :not_found}

      iex> Gimme.dat(%{}, "gimme_no_such_atom")
      {:error, :not_found}
  """
  @spec dat(map(), String.t() | atom()) :: {:ok, any()} | {:error, :not_found}
  def dat(thing, key) do
    with :error <- Map.fetch(thing, key),
         :error <- fetch_other(thing, key) do
      {:error, :not_found}
    end
  end

  @doc """
  Like `dat/2` but just gimme the value. Raises `KeyError` if it's not there.

      iex> Gimme.dat!(%{"key" => 1}, :key)
      1
  """
  @spec dat!(map(), String.t() | atom()) :: any()
  def dat!(thing, key) do
    case dat(thing, key) do
      {:ok, value} -> value
      {:error, :not_found} -> raise KeyError, key: key, term: thing
    end
  end

  defp fetch_other(thing, key) when is_atom(key), do: Map.fetch(thing, Atom.to_string(key))

  defp fetch_other(thing, key) when is_binary(key) do
    Map.fetch(thing, String.to_existing_atom(key))
  rescue
    ArgumentError -> :error
  end
end
