defmodule GameTest do
  @moduledoc """
  run with "mix test --no-start"
  """
  use ExUnit.Case
  use Supervisor
  require Logger

  doctest Hangman


  setup %{dictionary: dictionary, length: length, guesses: guesses} do
    children = [
      worker(Game.Supervisor, [])
    ]
    opts = [strategy: :one_for_one, name: Hangman.Supervisor]
    Supervisor.start_link(children, opts)

    game = Game.Supervisor.start [dictionary_file: dictionary,
                          word_length: length,
                          number_of_guesses: guesses]
    {:ok, %{supervisor: game}}
  end

  @tag :GameTest
  @tag dictionary: "short_dictionary.txt"
  @tag length: 4
  @tag guesses: 6
  test "Game step", context do

    IO.puts "context: #{inspect context}"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 9
  end

end
