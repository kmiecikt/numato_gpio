defmodule Numato.Gpio do
  use GenStage

  defmodule State do
    defstruct [
      uart_pid: nil,
      last_command: nil
    ]
  end

  def start_link(uart_pid) do
    GenStage.start_link(__MODULE__, uart_pid)
  end

  def init(uart_pid) when is_pid(uart_pid) do
    {:producer, %State{uart_pid: uart_pid}}
  end

  def init(com_port) when is_bitstring(com_port) do
    {:ok, uart_pid} = Circuits.UART.start_link()
    :ok = Circuits.UART.open(uart_pid, com_port,
      speed: 115200,
      active: true,
      framing: {Numato.UART.Framing, separator: "\r\n"})
    {:producer, %State{uart_pid: uart_pid}}
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  @doc """
  Returns Numato firmware version.
  """
  def ver(pid) when is_pid(pid) do
    GenStage.call(pid, :ver)
  end

  @doc """
  Reads ID of the Numato module.
  """
  def id_get(pid) when is_pid(pid) do
    GenStage.call(pid, :id_get)
  end

  @doc """
  Writes ID of the Numato module. The ID must be a string with exactly 8 characters.
  """
  def id_set(pid, id) when is_pid(pid) and is_bitstring(id) and byte_size(id) == 8 do
    GenStage.call(pid, {:id_set, id})
  end

  @doc """
  Reads the digial input status for the given GPIO. Returns 0 for low and 1 for high state.
  """
  def gpio_read(pid, gpio) when is_pid(pid) and is_integer(gpio) do
    GenStage.call(pid, {:gpio_read, gpio})
  end

  @doc """
  Sets the GPIO output status to either low (value `0`) or high (value `1`).
  """
  def gpio_write(pid, gpio, value) when is_pid(pid) and is_integer(gpio) and (value == 0 or value == 1) do
    GenStage.call(pid, {:gpio_write, gpio, value})
  end

  @doc """
  Sets mask for subsequent GPIO `Numato.Gpio.gpio_writeall` and `Numato_Gpio.gpio_iodir` commands.
  A 0 in a bit position mask the corresponding GPIO and any update to that GPIO is ignored
  during `Numato.Gpio.gpio_iodir` and `Numato.Gpio.gpio_writeall` operations.
  """
  def gpio_iomask(pid, iomask) when is_bitstring(iomask) do
    GenStage.call(pid, {:gpio_iomask, iomask})
  end

  @doc """
  Sets the direction of all GPIOs in a single operation.
  A 0 in a bit position configures that GPIO as output and 1 configures it as input.

  This operation respects the `iomask`, set using `Numato.Gpio.gpio_iomask()` function.
  """
  def gpio_iodir(pid, iodir) when is_bitstring(iodir) do
    GenStage.call(pid, {:gpio_iodir, iodir})
  end

  @doc """
  Reads the status of all GPIOs in a single operation.
  """
  def gpio_readall(pid) when is_pid(pid) do
    GenStage.call(pid, :gpio_readall)
  end

  @doc """
  Enables GPIOs input change notifications. When notifications are enabled, this `GenStage` process
  will produce events that are tuples with three elemetns: `{current_value, previous_value, iodir}`.
  """
  def gpio_notify_on(pid) when is_pid(pid) do
    GenStage.call(pid, :gpio_notify_on)
  end

  @doc """
  Disables GPIOs input change notifications.
  """
  def gpio_notify_off(pid) when is_pid(pid) do
    GenStage.call(pid, :gpio_notify_off)
  end

  @doc """
  Controls al GPIOs in a single operation.

  This operation respects the `iomask`, set using `Numato.Gpio.gpio_iomask()` function.
  """
  def gpio_writeall(pid, value) when is_pid(pid) do
    GenStage.call(pid, {:gpio_writeall, value})
  end

  @doc """
  Returns information whether notifications are enabled (`true`) or disabled ('false`).
  """
  def gpio_notify_get(pid) when is_pid(pid) do
    GenStage.call(pid, :gpio_notify_get)
  end

  @doc """
  Reads the analog voltage present at the given ADC input. Responses are
  integeres in range 0 - 1023.
  """
  def adc_read(pid, input) when is_pid(pid) and is_integer(input) do
    GenStage.call(pid, {:adc_read, input})
  end

  def handle_call(:ver, from, state) do
    command_text = Numato.Commands.ver()
    send_call(command_text, {:ver, from}, state)
  end

  def handle_call(:id_get, from, state) do
    command_text = Numato.Commands.id_get()
    send_call(command_text, {:id_get, from}, state)
  end

  def handle_call({:id_set, id}, _from, state) do
    command_text = Numato.Commands.id_set(id)
    send_info(command_text, state)
  end

  def handle_call({:gpio_read, gpio}, from, state) do
    command_text = Numato.Commands.gpio_read(gpio)
    send_call(command_text, {:gpio_read, from}, state)
  end

  def handle_call({:gpio_write, gpio, value}, _from, state) do
    command_text = Numato.Commands.gpio_write(gpio, value)
    send_info(command_text, state)
  end

  def handle_call({:gpio_iomask, iomask}, _from, state) do
    command_text = Numato.Commands.gpio_iomask(iomask)
    send_info(command_text, state)
  end

  def handle_call({:gpio_iodir, iodir}, _from, state) do
    command_text = Numato.Commands.gpio_iodir(iodir)
    send_info(command_text, state)
  end

  def handle_call(:gpio_readall, from, state) do
    command_text = Numato.Commands.gpio_readall()
    send_call(command_text, {:gpio_readall, from}, state)
  end

  def handle_call(:gpio_notify_on, _from , state) do
    command_text = Numato.Commands.gpio_notify_on()
    send_info(command_text, state)
  end

  def handle_call(:gpio_notify_off, _from, state) do
    command_text = Numato.Commands.gpio_notify_off()
    send_info(command_text, state)
  end

  def handle_call(:gpio_notify_get, from, state) do
    command_text = Numato.Commands.gpio_notify_get()
    send_call(command_text, {:gpio_notify_get, from}, state)
  end

  def handle_call({:gpio_writeall, values}, _from, state) do
    command_text = Numato.Commands.gpio_writeall(values)
    send_info(command_text, state)
  end

  def handle_call({:adc_read, input}, from, state) do
    command_text = Numato.Commands.adc_read(input)
    send_call(command_text, {:adc_read, from}, state)
  end

  def handle_info({:circuits_uart, _, line}, state) do
    response = Numato.Responses.parse(line)
    case response do
      :echo ->
        {:noreply, [], state}
      {:notification, previous, current, iodir} ->
        {events, new_state} = process_notification(previous, current, iodir, state)
        {:noreply, events, new_state}
      _ ->
        :ok = reply_to_command(state.last_command, response)
        {:noreply, [], %State{state | last_command: nil}}
    end
  end

  defp send_info(command_text, state) do
    response = Circuits.UART.write(state.uart_pid, command_text)
    {:reply, response, [], %State{state | last_command: nil}}
  end

  defp send_call(command_text, command_tuple, state) do
    case Circuits.UART.write(state.uart_pid, command_text) do
      :ok -> {:noreply, [], %State{state | last_command: command_tuple}}
      error -> {:reply, error, [], %State{state | last_command: nil}}
    end
  end

  defp process_notification(previous, current, iodir, state) do
    changes = Numato.Utils.get_changed_ports(previous, current, iodir)
    {[{:notification, changes}], state}
  end

  defp reply_to_command({:gpio_read, from}, {:int, value}) when value == 0 or value == 1 do
    GenStage.reply(from, value)
  end

  defp reply_to_command({:id_get, from}, {:id, value}) do
    GenStage.reply(from, value)
  end

  defp reply_to_command({:id_get, from}, {:bits, value}) do
    GenStage.reply(from, Base.encode16(value))
  end

  defp reply_to_command({:ver, from}, {:bits, value}) do
    GenStage.reply(from, Base.encode16(value))
  end

  defp reply_to_command({:gpio_readall, from}, {:bits, value}) do
    GenStage.reply(from, value)
  end

  defp reply_to_command({:adc_read, from}, {:int, value}) do
    GenStage.reply(from, value)
  end

  defp reply_to_command({:gpio_notify_get, from}, {:notify, value}) do
    GenStage.reply(from, value)
  end
end
