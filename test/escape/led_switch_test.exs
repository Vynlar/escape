defmodule Escape.LEDSwitchTest do
  use ExUnit.Case

  alias Escape.LEDSwitch
  alias Circuits.GPIO

  test "should trigger if one input is on" do
    {:ok, input} = GPIO.open(1, :output)
    GPIO.write(input, 1)

    {:ok, output} = GPIO.open(3, :output)
    GPIO.write(output, 0)
    assert GPIO.read(output) == 0

    {:ok, pid} = LEDSwitch.start_link(%{input_pins: [0], output_pin: 2, notify: self()})

    GPIO.write(input, 0)
    assert_receive :solved
    assert GPIO.read(output) == 1

    Process.exit(pid, :normal)
  end

  test "should trigger if two inputs are on" do
    {:ok, input1} = GPIO.open(1, :output)
    GPIO.write(input1, 1)
    {:ok, input2} = GPIO.open(3, :output)
    GPIO.write(input2, 1)

    {:ok, output} = GPIO.open(5, :output)

    {:ok, pid} = LEDSwitch.start_link(%{input_pins: [0, 2], output_pin: 4, notify: self()})

    assert GPIO.read(output) == 0
    GPIO.write(input1, 0)
    assert GPIO.read(output) == 0

    GPIO.write(input2, 0)
    assert_receive :solved
    assert GPIO.read(output) == 1

    Process.exit(pid, :normal)
  end

  test "should be able to reset" do
    {:ok, input} = GPIO.open(1, :output)
    GPIO.write(input, 1)

    {:ok, output} = GPIO.open(3, :output)
    GPIO.write(output, 0)
    assert GPIO.read(output) == 0

    {:ok, pid} = LEDSwitch.start_link(%{input_pins: [0], output_pin: 2, notify: self()})

    GPIO.write(input, 0)
    assert_receive :solved
    assert GPIO.read(output) == 1

    LEDSwitch.reset()
    assert GPIO.read(output) == 0

    Process.exit(pid, :normal)
  end
end
