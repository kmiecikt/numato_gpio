defmodule Numato.UART.Framing do
  @moduledoc false
  @behaviour Circuits.UART.Framing

  @line_separator "\n"

  @notification_prefix "#"
  @notification_length 27         # Excludes the prefix
  @max_length 50

  defmodule State do
    defstruct [
      pending_characters: [],
      mode: :line
    ]
  end

  def init(_args) do
    {:ok, %State{}}
  end

  def add_framing(data, state) do
    {:ok, data <> @line_separator, state}
  end

  def remove_framing(data, state) do
    {new_mode, new_pending_characters, lines} = scan(state.mode, data, state.pending_characters, [])
    new_state = %State{pending_characters: new_pending_characters, mode: new_mode}

    case buffer_empty?(new_state) do
      true -> {:ok, lines, new_state}
      false -> {:in_frame, lines, new_state}
    end
  end

  defp scan(:line, data, pending_characters, lines) do
    scan_line(data, pending_characters, lines)
  end

  defp scan(:notification, data, pending_characters, lines) do
    scan_notification(data, pending_characters, lines)
  end

  defp scan_line(data, pending_characters, lines) do
    case data do
      <<@line_separator, rest::binary>> ->
        last_line = to_line(pending_characters)
        scan_line(rest, [], [last_line | lines])
      <<@notification_prefix, rest::binary>> ->
        last_line = to_line(pending_characters)
        scan_notification(rest, [], [last_line | lines])
      _ when length(pending_characters) == @max_length ->
        last_line = to_line(pending_characters)
        scan_line(data, [], [last_line | lines])
      <<next::binary-size(1), rest::binary>> ->
        scan_line(rest, [next | pending_characters], lines)
      <<>> ->
        {:line, pending_characters, lines}
    end
  end

  defp scan_notification(data, pending_characters, lines) when length(pending_characters) == @notification_length do
    last_line = to_line(pending_characters)
    scan_line(data, [], [last_line | lines])
  end

  defp scan_notification(data, pending_characters, lines) do
    case data do
      <<next::binary-size(1), rest::binary>> ->
        scan_notification(rest, [next | pending_characters], lines)
      <<>> ->
        {:notification, pending_characters, lines}
    end
  end

  defp to_line(characters) do
    characters |> Enum.reverse() |> to_string()
  end

  def frame_timeout(state) do
    line = {:partial, to_line(state.pending_characters)}
    new_state = %State{pending_characters: [], mode: :line}
    {:ok, [line], new_state}
  end

  def flush(:receive, _state) do
    %State{}
  end

  def flush(:both, _state) do
    %State{}
  end

  def flush(:transmit, state) do
    state
  end

  def buffer_empty?(state) do
    case state.pending_characters do
      [] -> true
      _ -> false
    end
  end
end
