defmodule Numato.Commands do
  @moduledoc """
  Module for generating Numato GPIO commands
  """

  @doc ~S"""
  Creates command for setting id.

  ## Examples:

    iex> Numato.Commands.id_set("12345678")
    "id set 12345678"

  """
  def id_set(id) when is_bitstring(id) and byte_size(id) == 8 do
    "id set #{id}"
  end

  @doc ~S"""
  Creates command for setting or clearing a single GPIO.
  ## Examples:

    iex> Numato.Commands.gpio_set(13, 1)
    "gpio set D"

    iex> Numato.Commands.gpio_set(2, 0)
    "gpio clear 2"
  """
  def gpio_set(gpio, state) when is_integer(gpio) and is_integer(state) do
    case state do
      0 -> "gpio clear #{gpio_number_to_id(gpio)}"
      1 -> "gpio set #{gpio_number_to_id(gpio)}"
    end
  end

  @doc ~S"""
  Creates command for reading a single GPIO.

  ## Examples:

    iex> Numato.Commands.gpio_read(3)
    "gpio read 3"
  """
  def gpio_read(gpio) do
    "gpio read #{gpio_number_to_id(gpio)}"
  end

  @doc ~S"""
  Creates command for setting iomask.

  ## Examples

    iex> Numato.Commands.gpio_iomask(<<255, 1, 254, 2>>)
    "gpio iomask ff01fe02"
  """
  def gpio_iomask(iomask) when is_bitstring(iomask) and bit_size(iomask) == 32 do
    "gpio iomask #{Base.encode16(iomask) |> String.downcase()}"
  end

  @doc ~S"""
  Creates command for setting iodir.

  ## Examples

    iex> Numato.Commands.gpio_iodir(<<254, 2, 255, 1>>)
    "gpio iodir fe02ff01"
  """
  def gpio_iodir(iodir) do
    "gpio iodir #{Base.encode16(iodir) |> String.downcase()}"
  end

  @doc ~S"""
  Creates command for reading all GPIO states in a single operation.

  ## Examples

    iex> Numato.Commands.gpio_readall()
    "gpio readall"
  """
  def gpio_readall() do
    "gpio readall"
  end

  @doc ~S"""
  Creates command for turning on or off GPIO notifications.

  ## Examples

    iex> Numato.Commands.gpio_notify(true)
    "gpio notify on"

    iex> Numato.Commands.gpio_notify(false)
    "gpio notify off"
  """
  def gpio_notify(on) do
    suffix = if on, do: "on", else: "off"

    "gpio notify #{suffix}"
  end

  @doc ~S"""
  Creates command for getting state of notifications.

  ## Examples

    iex> Numato.Commands.gpio_notify_get()
    "gpio notify get"
  """
  def gpio_notify_get() do
    "gpio notify get"
  end

  @doc ~S"""
  Creates command for writing all GPIOs in a single operation.

  ## Examples

    iex> Numato.Commands.gpio_writeall(<<255, 254, 253, 252>>)
    "gpio writeall fffefdfc"
  """
  def gpio_writeall(values) when is_bitstring(values) and bit_size(values) == 32 do
    "gpio writeall #{Base.encode16(values) |> String.downcase()}"
  end

  @doc ~S"""
  Creates command for reading a single ADC input.

  ## Examples

    iex> Numato.Commands.adc_read(1)
    "adc read 1"
  """
  def adc_read(gpio) when is_integer(gpio) do
    "adc read #{gpio_number_to_id(gpio)}"
  end

  defp gpio_number_to_id(gpio) when gpio <= 9 do
    "#{gpio}"
  end

  defp gpio_number_to_id(gpio) when gpio > 9 do
    <<?A + gpio - 10>>
  end
end
