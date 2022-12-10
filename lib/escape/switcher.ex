defmodule Escape.Switcher do
  use GenServer
  require Logger
  alias Circuits.GPIO

  @delay 2000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_) do
    Process.send_after(self(), :loop, @delay)
    {:ok, gpio} = GPIO.open(60, :output)
    {:ok, %{state: :on, gpio: gpio}}
  end

  def handle_info(:loop, %{state: :on, gpio: gpio} = state) do
    Process.send_after(self(), :loop, @delay)
    Logger.info("turning off")
    GPIO.write(gpio, 1)
    {:noreply, Map.put(state, :state, :off)}
  end

  def handle_info(:loop, %{state: :off, gpio: gpio} = state) do
    Process.send_after(self(), :loop, @delay)
    Logger.info("turning on")
    GPIO.write(gpio, 0)
    {:noreply, Map.put(state, :state, :on)}
  end
end
