defmodule Numato.Responses do
  @doc ~S"""
  Parses result of ver command.

  ## Examples

    iex> Numato.Responses.parse_ver("1.2.3\r\n")
    "1.2.3"
  """
  def parse_ver(line) do
    String.trim(line)
  end

  @doc ~S"""
  Parsers result of id get command.

  ## Examples

    iex> Numato.Responses.parse_id_get("12345678\n")
    "12345678"

    iex> Numato.Responses.parse_id_get("123")
    {:error, "Invalid Numato id: expected 8 characters, got 3"}
  """
  def parse_id_get(line) do
    result = String.trim(line)

    case String.length(result) do
      8 -> result
      length -> {:error, "Invalid Numato id: expected 8 characters, got #{length}"}
    end
  end

  @doc ~S"""
  Parses result of the gpio read command.

  ## Examples

    iex> Numato.Responses.parse_gpio_read("on")
    1

    iex> Numato.Responses.parse_gpio_read("off\r")
    0

    iex> Numato.Responses.parse_gpio_read("true")
    {:error, "Invalid Numato gpio read result: expected 'on' or 'off', got 'true'"}
  """
  def parse_gpio_read(line) do
    case String.trim(line) do
      "on"  -> 1
      "off" -> 0
      other -> {:error, "Invalid Numato gpio read result: expected 'on' or 'off', got '#{other}'"}
    end
  end

  @doc ~S"""
  Parses result of the gpio readall command and converts it to bitstring, where each
  bit represents one GPIO.

  ## Examples

    iex> Numato.Responses.parse_gpio_readall("FAFBFCFD\n")
    <<250, 251, 252, 253>>

    iex> Numato.Responses.parse_gpio_readall("00010203\r\n")
    <<0, 1, 2, 3>>

    iex> Numato.Responses.parse_gpio_readall("12AZ")
    {:error, "Invalid hex value: expected 8 characters, got 4"}
  """
  def parse_gpio_readall(line) do
    String.trim(line) |> parse_hex_value()
  end

  @doc ~S"""
  Parses result of the gpio notification and converts it to tuple with three properties:
  - current value (bitstring)
  - previous value (bitstring)
  - iodir

  ## Examples

    iex> Numato.Responses.parse_gpio_notify("01020304 05060708 FAFBFCFD\r\n")
    {<<1, 2, 3, 4>>, <<5, 6, 7, 8>>, <<250, 251, 252, 253>>}

    iex> Numato.Responses.parse_gpio_notify("0010123")
    {:error, "Invalid notify result: expected three 32-bit hexadecimal integers"}
  """
  def parse_gpio_notify(line) do
    parts = String.split(line) |> Enum.map(&parse_hex_value/1)
    case parts do
      [current, previous, iodir] when is_bitstring(current) and is_bitstring(previous) and is_bitstring(iodir)
        -> {current, previous, iodir}
      _ -> {:error, "Invalid notify result: expected three 32-bit hexadecimal integers"}
    end
  end

  defp parse_hex_value(value) do
    case String.length(value) do
      8     -> <<String.to_integer(value, 16)::size(32)>>
      length -> {:error, "Invalid hex value: expected 8 characters, got #{length}"}
    end
  end
end
