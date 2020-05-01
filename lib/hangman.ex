defmodule Hangman do
  @moduledoc """
  The application entry point for `Hangman`.

  Run with "mix run"
  """
  use Application
  use Supervisor
  require Logger


  @impl true
  def start(_type, _args) do

    children = [
      worker(Game.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Hangman.Supervisor]
    Supervisor.start_link(children, opts)

    IO.puts ""
    IO.puts ""


    length = IO.gets("Length of word? ")
      |> String.trim
      |> String.to_integer

    guesses = IO.gets("Number of guesses? ")
      |> String.trim
      |> String.to_integer

    Game.Supervisor.start [dictionary_file: "dictionary.txt",
                          word_length: length,
                          number_of_guesses: guesses]

    play Game.guesses_remaining

    {:ok, self()}
  end

  @impl true
  def init(args) do
     Logger.info "#{__MODULE__} Initing args: #{inspect args}"
     {:ok, []}
  end

  def play(count) when count <= 0 do
    IO.puts "guessed: [#{Game.guessed}]"
    IO.puts "#{Game.pattern}"
    IO.puts "Word was: #{Game.winning_word}"
    IO.puts ""
    IO.puts "Sorry you lose"
  end
  def play(_count) do
    IO.puts ""
    IO.puts "guesses left: #{Game.guesses_remaining}"
    IO.puts "words left: #{Game.word_count}"
    #IO.puts "guessed: [#{Enum.sort(Game.guessed)}]"
    IO.puts "guessed: [#{Game.guessed}]"
    IO.puts "#{Game.pattern}"

    guess = String.trim(IO.gets "Next guess? ")

    if guess in Game.guessed do
      IO.puts ""
      IO.puts ""
      IO.puts "#{guess} already guessed. Try again!"
      play Game.guesses_remaining
    else
      Game.make_guess guess

      if Game.pattern =~ "-" do
        play Game.guesses_remaining
      else
        IO.puts ""
        IO.puts "#{Game.winning_word}"
        IO.puts "You won!"
        IO.puts ""
        IO.puts ""
        IO.puts ""
      end
    end
  end
end
