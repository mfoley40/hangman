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
  test "Game setup", context do

    IO.puts "context: #{inspect context}"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 9
    assert Game.guesses_remaining == 6
    assert Game.guessed == []

    Game.Supervisor.stop
  end

  @tag :GameTest
  @tag dictionary: "short_dictionary.txt"
  @tag length: 4
  @tag guesses: 6
  test "Game guess" do

    Game.make_guess "a"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 6
    assert Game.guesses_remaining == 5
    assert Game.guessed == ["a"]

    Game.make_guess "l"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 3
    assert Game.guesses_remaining == 4
    assert Game.guessed == ["a", ", ", "l"]

    Game.make_guess "y"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 3
    assert Game.guesses_remaining == 3
    assert Game.guessed == ["a", ", ", "l", ", ", "y"]

    Game.make_guess "x"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 2
    assert Game.guesses_remaining == 2
    assert Game.guessed == ["a", ", ", "l", ", ", "y", ", ", "x"]

    Game.make_guess "h"
    assert Game.pattern == "- - - -"
    assert Game.word_count == 1
    assert Game.guesses_remaining == 1
    assert Game.guessed == ["a", ", ", "l", ", ", "y", ", ", "x", ", ", "h"]

    Game.make_guess "o"
    assert Game.pattern == "- o o -"
    assert Game.word_count == 1
    assert Game.guesses_remaining == 1
    assert Game.guessed == ["a", ", ", "l", ", ", "y", ", ", "x", ", ", "h", ", ", "o"]

    Game.make_guess "g"
    assert Game.pattern == "g o o -"
    assert Game.word_count == 1
    assert Game.guesses_remaining == 1
    assert Game.guessed == ["a", ", ", "l", ", ", "y", ", ", "x", ", ", "h", ", ", "o", ", ", "g"]

    Game.make_guess "d"
    assert Game.pattern == "g o o d"
    assert Game.word_count == 1
    assert Game.guesses_remaining == 1
    assert Game.guessed == ["a", ", ", "l", ", ", "y", ", ", "x", ", ", "h", ", ", "o", ", ", "g", ", ", "d"]
    assert Game.word_count == 1
    assert Game.winning_word == "good"

    Game.Supervisor.stop

  end

end
