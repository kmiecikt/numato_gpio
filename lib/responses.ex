defmodule Numato.Responses do
  @doc ~S"""
  Parser response received from COM port.

  ## Examples

    iex> Numato.Responses.parse("ABCDZDFF")
    {:id, "ABCDZDFF"}

    iex> Numato.Responses.parse("gpio notify enabled")
    {:notify, true}

    iex> Numato.Responses.parse("gpio notify disabled")
    {:notify, false}

    iex> Numato.Responses.parse("0102FFFE")
    {:bits, <<1, 2, 255, 254>>}

    iex> Numato.Responses.parse("1023")
    {:int, 1023}

    iex> Numato.Responses.parse("01020304 FFFEFDFC 0102FDFC")
    {:notification, <<1, 2, 3, 4>>, <<255, 254, 253, 252>>, <<1, 2, 253, 252>>}

    iex> Numato.Responses.parse("ver")
    :echo

    iex> Numato.Responses.parse("id set 12345678")
    :echo

    iex> Numato.Responses.parse("id get")
    :echo

    iex> Numato.Responses.parse("gpio set 1")
    :echo

    iex> Numato.Responses.parse("gpio clear H")
    :echo

    iex> Numato.Responses.parse("gpio read 1")
    :echo

    iex> Numato.Responses.parse("gpio iomask FF01FE02")
    :echo

    iex> Numato.Responses.parse("gpio iodir FF01FE02")
    :echo

    iex> Numato.Responses.parse("gpio readall")
    :echo

    iex> Numato.Responses.parse("gpio writeall 12345678")
    :echo

    iex> Numato.Responses.parse("gpio notify on")
    :echo

    iex> Numato.Responses.parse("gpio notify off")
    :echo

    iex> Numato.Responses.parse("gpio notify get")
    :echo

    iex> Numato.Responses.parse("adc read A")
    :echo

    iex> Numato.Responses.parse(">")
    :echo

    iex> Numato.Responses.parse("gpi123456789 read")
    :error
  """

  def parse(line) do
    lexemes = String.trim(line) |> String.trim(">") |> String.split()
    tokens = lexemes
      |> Enum.map(&recognize_token/1)
      |> Enum.filter(fn t -> t != :prompt end)
      |> Enum.to_list()

    case tokens do
      [{:id, token}] -> {:id, token}
      [:gpio, :notify, :enabled] -> {:notify, true}
      [:gpio, :notify, :disabled] -> {:notify, false}
      [{:hex, token}] -> {:bits, parse_hex(token)}
      [{:int, token}] -> {:int, parse_int(token)}
      [{:hex, previous_token}, {:hex, current_token}, {:hex, iodir_token}] ->
        {:notification, parse_hex(previous_token), parse_hex(current_token), parse_hex(iodir_token)}
      [:ver] -> :echo
      [:id, :set, {:id, _}] -> :echo
      [:id, :set, {:hex, _}] -> :echo
      [:id, :get] -> :echo
      [:gpio, :set, {:int, _}] -> :echo
      [:gpio, :clear, {:int, _}] -> :echo
      [:gpio, :read, {:int, _}] -> :echo
      [:gpio, :iomask, {:hex, _}] -> :echo
      [:gpio, :iodir, {:hex, _}] -> :echo
      [:gpio, :readall] -> :echo
      [:gpio, :writeall, {:hex, _}] -> :echo
      [:gpio, :notify, :on] -> :echo
      [:gpio, :notify, :off] -> :echo
      [:gpio, :notify, :get] -> :echo
      [:adc, :read, {:int, _}] -> :echo
      [] -> :echo
      _ -> :error
    end
  end

  def recognize_token("ver"), do: :ver
  def recognize_token("gpio"), do: :gpio
  def recognize_token("id"), do: :id
  def recognize_token("set"), do: :set
  def recognize_token("get"), do: :get
  def recognize_token("on"), do: :on
  def recognize_token("off"), do: :off
  def recognize_token("enabled"), do: :enabled
  def recognize_token("disabled"), do: :disabled
  def recognize_token("clear"), do: :clear
  def recognize_token("read"), do: :read
  def recognize_token("iodir"), do: :iodir
  def recognize_token("iomask"), do: :iomask
  def recognize_token("readall"), do: :readall
  def recognize_token("writeall"), do: :writeall
  def recognize_token("notify"), do: :notify
  def recognize_token("adc"), do: :adc
  def recognize_token(">"), do: :prompt

  def recognize_token(lexeme) when is_bitstring(lexeme) and byte_size(lexeme) == 8 do
    is_hex = lexeme
      |> to_charlist()
      |> Enum.all?(fn c -> (c >= ?0 and c <= ?9) or (c >= ?A and c <= ?F)  or (c >= ?a and c <= ?f) end)

    if is_hex do
      {:hex, lexeme}
    else
      {:id, lexeme}
    end
  end

  def recognize_token(lexeme) when is_bitstring(lexeme) and byte_size(lexeme) == 1 do
    [x] = to_charlist(lexeme)
    if (x >= ?0 and x <= ?9) or (x >= ?A and x <= ?Z) do
      {:int, lexeme}
    else
      :error
    end
  end

  def recognize_token(lexeme) when is_bitstring(lexeme) and byte_size(lexeme) <= 4 do
    is_int = lexeme
      |> to_charlist()
      |> Enum.all?(fn c -> c >= ?0 and c <= ?9 end)

    if is_int do
      {:int, lexeme}
    else
      :error
    end
  end

  def recognize_token(lexeme) do
    {:any, lexeme}
  end

  defp parse_hex(value) do
    <<String.to_integer(value, 16)::size(32)>>
  end

  defp parse_int(value) do
    String.to_integer(value)
  end
end
