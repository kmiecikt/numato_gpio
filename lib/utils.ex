defmodule Numato.Utils do
  @doc ~S"""
  Returns list of changed ports.

  ## Examples

    iex> Numato.Utils.get_changed_ports(<<0xFF>>, <<0xFE>>, <<0xFF>>)
    [{0, :off}]

    iex> Numato.Utils.get_changed_ports(<<0xFC>>, <<0xFF>>, <<0xFF>>)
    [{0, :on}, {1, :on}]

    iex> Numato.Utils.get_changed_ports(<<0xFC>>, <<0xFF>>, <<0x01>>)
    [{0, :on}]
  """
  def get_changed_ports(previous, current, iodir) do
    get_changes(previous, current, iodir, bit_size(previous) - 1, [])
  end

  defp get_changes(<<p::size(1), rest_p::bitstring>>, <<c::size(1), rest_c::bitstring>>, <<i::size(1), rest_i::bitstring>>, position, result) do
    new_result = detect_change(p, c, i, position, result)
    get_changes(rest_p, rest_c, rest_i, position - 1, new_result)
  end

  defp get_changes(<<>>, <<>>, <<>>, _, result) do
    result
  end

  defp detect_change(_p, _c, 0, _position, result) do
    result
  end

  defp detect_change(p, c, 1, position, result) do
    case {p, c} do
      {1, 0} -> [{position, :off} | result]
      {0, 1} -> [{position, :on} | result]
      _ -> result
    end
  end
end
