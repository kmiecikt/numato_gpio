defmodule Numato.State do
  defstruct [
    com_pid: nil,
    notify_on: false,
    input_mask: <<0xFFFFFFFF>>,
    gpio_state: <<0xFFFFFFFF>>,
    last_command: nil
  ]
end
