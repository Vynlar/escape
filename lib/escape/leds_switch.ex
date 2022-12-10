defmodule Escape.LEDSwitch do
  use GenServer
  require Logger
  alias Circuits.GPIO

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  defp initial_switch_state(pins) do
    pins
    |> Enum.map(fn pin -> {pin, 1} end)
    |> Enum.into(%{})
  end

  @impl true
  def init(%{input_pins: pins, output_pin: output_pin} = args) do
    notify = Map.get(args, :notify, nil)

    inputs =
      pins
      |> Enum.map(&setup_input/1)
      |> Enum.map(&elem(&1, 1))

    {:ok, output} = GPIO.open(output_pin, :output)

    switch_state = initial_switch_state(pins)

    state =
      %{switches: switch_state, output_pin: output_pin}
      |> Map.put(:inputs, inputs)
      |> Map.put(:output, output)
      |> Map.put(:notify, notify)

    {:ok, state}
  end

  @impl true
  def handle_info({:circuits_gpio, pin, _timestamp, value}, state) do
    Logger.info("Pin #{pin} changed to #{value}")

    new_state =
      state
      |> Map.update!(
        :switches,
        fn switches ->
          switches
          |> Map.put(pin, value)
        end
      )

    maybe_turn_on_light(new_state, state.output, state.notify)

    {:noreply, new_state}
  end

  def maybe_turn_on_light(state, output, notify) do
    if is_success(state) do
      Logger.info("Successful solve!")
      if notify do
        send(notify, :solved)
      end
      GPIO.write(output, 1)
    end
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def handle_call(:reset, _from, state) do
    Logger.info('Resetting')
    # Turn off output
    GPIO.write(state.output, 0)

    {:reply, :success, Map.put(state, :switches, initial_switch_state(Map.keys(state.switches)))}
  end

  # Helpers

  defp is_success(%{switches: switches}) do
    switches
    |> Map.values()
    |> Enum.map(fn val ->
      case val do
        0 -> true
        1 -> false
      end
    end)
    |> Enum.all?()
  end

  defp setup_input(pin) do
    {:ok, gpio} = GPIO.open(pin, :input)
    GPIO.set_interrupts(gpio, :both)
    {:ok, gpio}
  end
end
