# Numato GPIO

Elixir module for communicating with [Numato 32-channel GPIO module](https://numato.com/docs/32-channel-usb-gpio-module-with-analog-inputs/).

## Installation

The package is available in [Hex](https://hex.pm/packages/numato_gpio) and it can be installed
by adding `numato_gpio` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:numato_gpio, "~> 0.1.0"}
  ]
end
```

## Usage
The `Numato.Gpio` module implements all the [Numato 32-channel GPIO module commands](https://numato.com/docs/32-channel-usb-gpio-module-with-analog-inputs/#the-commands-set-2). It's also a `GenServer` producer that sends notifications of input GPIO changes.

To start the process, you need to know a virtual COM port name associated with the Numato GPIO device. Assuming it is `ttyACM0` on your system, you can run the following:

```
iex> {:ok, pid} = Numato.Gpio.start_link("ttyACM0")
{:ok, #Reference<...>}

iex> Numato.Gpio.write(pid, 1, 1)
:ok

iex> Numato.Gpio.read(pid, 2)
0
```

To enable notifications, use the `gpio_notify_on` function:
```
iex> Numato.Gpio.gpio_notify_on(pid)
:ok
```

From this point, the module will work as a `GenStage` producer, with events in format `{gpio, new_state}`.

## API documentation
The [ExDoc](https://github.com/elixir-lang/ex_doc) documentation can be found at 
at [https://hexdocs.pm/numato_gpio](https://hexdocs.pm/numato_gpio).

