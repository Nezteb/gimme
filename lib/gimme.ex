defmodule Gimme do
  @moduledoc """
  Need to ship a feature but yo data is wack? Use `Gimme.dat(map, :key)`!
  """

  @not_keys [nil, true, false]

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

  Stored both ways? The exact match wins:

      iex> Gimme.dat(%{:key => 1, "key" => 2}, "key")
      {:ok, 2}

  `nil`, `true`, and `false` don't count as keys. Not even as strings:

      iex> Gimme.dat(%{nil: 1}, "nil")
      {:error, :not_found}
  """
  @spec dat(map(), String.t() | atom()) :: {:ok, any()} | {:error, :not_found}
  def dat(thing, key)
      when is_map(thing) and
             ((is_atom(key) and key not in @not_keys) or is_binary(key)) do
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
    with {:ok, atom} <- existing_atom(key), do: Map.fetch(thing, atom)
  end

  defp existing_atom(string) when string in ["nil", "true", "false"], do: :error

  defp existing_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    ArgumentError -> :error
  end
end
