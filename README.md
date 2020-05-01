# Hangman

A simple console-based application for the game of Hangman. However, this version
has a twist. The word selected ins't chosen until the last moment possible. There
is a word dictionary with approximately 120,000 words. After each letter guess
is made, (and the word length during the game setup) the list of possible
outcomes is chosen such that the largest number of words remain. If the word
isn't guessed in the allotted number of guesses, a random word is selected
from the remaining list of possible solutions.

To run the game:

  mix run

To run the tests:

  mix test --no-start

# NOTE:
The game doesn't perform any input validation. Thus, it is easy to crash the
game by entering characters when numbers are expected. Similarly, entering
multiple characters or a number for a letter guess will not crash the game,
but won't record a correct guess and will lower the guesses remaining count.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hangman` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hangman, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hangman](https://hexdocs.pm/hangman).
