#<editor-fold desc='Game.Supervisor Module'>
defmodule Game.Supervisor do
  @moduledoc """
  The Supervisor of the Game logic module
  """

  use Supervisor
  require Logger

  @name __MODULE__

  def start_link do
    Logger.info "#{__MODULE__} start_link"
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc """
  Start the child process with the default name
  """
  def start (args \\ []) do
    Logger.info "#{__MODULE__} start args: #{inspect args}"
    case Supervisor.start_child(@name, [args]) do
      {:ok, pid} -> Logger.info("#{__MODULE__} pid: #{inspect pid}")
      {:error, err} -> Logger.warn("#{__MODULE__} #{inspect err}")
      _ -> Logger.error("#{__MODULE__} What did start_child return?")
    end
  end

  @impl true
  def init(args) do
    Logger.info("#{__MODULE__} Init args #{inspect args}")

    Process.flag(:trap_exit, true)

    children = [
      worker(Game, [])
    ]
    opts = [strategy: :simple_one_for_one, name: Game]
#    Supervisor.start_link(children, opts)
    supervise(children, opts)
  end
end
#</editor-fold>


#<editor-fold desc='Game Module'>
defmodule Game do
  @moduledoc """
  The game logic for `Hangman`.
  """
  use GenServer
  require Logger


   #<editor-fold desc='Module State'>
   defmodule State do
     @moduledoc """
     Process state
     """
     @enforce_keys [:words]
     defstruct [:words,    # List of possible words in solution
       :word_length,       # The length of the word to be guessed
       :pattern,           # The pattern of the word and guesses
       :guesses,           # The number of guesses left before loosing
       :guessed            # Letters which have been guessed
   ]

   defimpl String.Chars do
     def to_string(state) do
       "State[patter: #{state.patter} guesses: #{state.guesses}" <>
       " guessed: #{inspect state.guessed} words left: #{length(state.words)}]"
     end
   end
   end
   #</editor-fold>


  def start(args \\ []) do
    Logger.info "#{__MODULE__} start args: #{inspect args}"
    id = Dict.get args, :id, :game
    GenServer.start __MODULE__, args, [name: id]
  end

  def start_link(args \\ []) do
    Logger.info "#{__MODULE__} start_link args: #{inspect args}"
    id = Dict.get args, :id, :game
    case GenServer.start_link __MODULE__, args, [name: id] do
      {:error, {:already_started, pid}} ->
        Logger.error "LeaderMonitor already running on: #{inspect pid}"
        {:ok, pid}
      ret ->
        ret
    end
  end

  @impl true
  def init(args) do
     Logger.info "#{__MODULE__} Initing args: #{inspect args}"
     length = 7
     words = case File.read("dictionary.txt") do
       {:ok, body}      -> match_words(body, length)
       {:error, reason} -> Logger.error "Couldn't read file: #{reason}"
                           []
     end

     pattern = make_pattern "", "", ""

    #
    # Register to get a terminate callback when shutting down
    #
    Process.flag(:trap_exit, true)

    state = %State {
      words: words,
      pattern: pattern,
      word_length: length,
      guesses: 8,
      guessed: []
    }
     {:ok, state}
  end

  #<editor-fold desc='Client API'>
  def word_count do
    GenServer.call :game, {:get_word_count}
  end

  def pattern do
    GenServer.call :game, {:get_pattern}
  end

  def guessed do
    GenServer.call :game, {:get_guessed}
  end

  def guesses_remaining do
    GenServer.call :game, {:get_guesses_remaining}
  end

  def make_guess guess do
    GenServer.call :game, {:guess, guess}
  end
  #</editor-fold>


  #<editor-fold desc='Server API'>
  @impl true
  def handle_call({:get_word_count}, _from, %{words: words} = state) do
    {:reply, length(words), state}
  end

  @impl true
  def handle_call({:get_pattern}, _from, %{pattern: pattern} = state) do
    {:reply, pattern, state}
  end

  @impl true
  def handle_call({:get_guessed}, _from, %{guessed: guessed} = state) do
    {:reply, guessed, state}
  end

  @impl true
  def handle_call({:get_guesses_remaining}, _from, %{guesses: guesses} = state) do
    {:reply, guesses, state}
  end

  @impl true
  def handle_call({:guess, guess}, _from, %{guesses: guesses, guessed: guessed} = state) do

    updated_guessed = case length(guessed) do
      0 -> [guess]
      _ -> guessed ++ [", ", guess]
    end

    {:reply, length(state.words), %{state | guesses: guesses - 1, guessed: updated_guessed}}
  end
  #</editor-fold>


  defp match_words contents, length do
    words = contents
    |> String.split("\n", trim: true)

    Logger.info "words: #{length(words)}"

    Enum.filter(words, fn(x) ->
      String.length(x) == length
    end)
  end

  defp make_pattern pattern, word, guess do
    "- - - - - - - -"
  end

  #<editor-fold desc='terminate Functions'>
  # handle the trapped exit call
  @impl true
  def terminate(:shutdown, state) do
    Logger.warn("#{__MODULE__} shutdown terminate")
    :normal
  end

  @impl true
  def terminate(reason, state) do
    Logger.error("#{__MODULE__} terminate reason: #{inspect reason} state #{inspect state}")
    :error
  end
  #</editor-fold>
end
#</editor-fold>
