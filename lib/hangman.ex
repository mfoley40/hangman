defmodule Hangman do
  @moduledoc """
  The application entry point for `Hangman`.
  """
  use Application
  use Supervisor
  require Logger


  @impl true
  def start(_type, _args) do
    Logger.info "#{__MODULE__} Hello World"

    children = [
      worker(Game.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Hangman.Supervisor]
    Supervisor.start_link(children, opts)

    Game.Supervisor.start

    Logger.info "#{__MODULE__} words left: #{Game.word_count}"

#    guess = IO.gets "Next guess? "
#    IO.puts String.trim(guess)

    play Game.guesses_remaining

    {:ok, self}
  end

  def play(count) when count <= 0 do
    IO.puts "You lost!"
    IO.puts "guessed: [#{Game.guessed}]"
    IO.puts "#{Game.pattern}"
  end
  def play(_count) do
    IO.puts ""
    IO.puts "guesses left: #{Game.guesses_remaining}"
    IO.puts "words left: #{Game.word_count}"
    IO.puts "guessed: [#{Game.guessed}]"
    IO.puts "#{Game.pattern}"

    guess = String.trim(IO.gets "Next guess? ")

    if guess in Game.guessed do
      IO.puts "#{guess} already guessed. Try again!"
      play Game.guesses_remaining
    else
      Game.make_guess guess
      play Game.guesses_remaining
    end

  end

end
