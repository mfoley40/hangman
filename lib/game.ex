#<editor-fold desc='Game.Supervisor Module'>
defmodule Game.Supervisor do
  @moduledoc """
  The Supervisor of the Game logic module
  """

  use Supervisor
  require Logger

  @name __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc """
  Start the child process with the default name
  """
  def start (args \\ []) do
    #Logger.info "#{__MODULE__} start args: #{inspect args}"
    case Supervisor.start_child(@name, [args]) do
      {:ok, pid} -> Logger.info("#{__MODULE__} pid: #{inspect pid}")
      {:error, err} -> Logger.warn("#{__MODULE__} #{inspect err}")
      _ -> Logger.error("#{__MODULE__} What did start_child return?")
    end
  end

  @impl true
  def init(_args) do
    #Logger.info("#{__MODULE__} Init args #{inspect args}")

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
     defstruct [:words,     # List of possible words in solution
       :word_length,        # The length of the word to be guessed
       :pattern,            # The pattern of the word and guesses
       :guesses,            # The number of guesses left before loosing
       :guessed,            # Letters which have been guessed
       :even_guesses        # True if the number of guesses allowed is even
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
    #Logger.info "#{__MODULE__} start args: #{inspect args}"
    id = Keyword.get args, :id, :game
    GenServer.start __MODULE__, args, [name: id]
  end

  def start_link(args \\ []) do
    #Logger.info "#{__MODULE__} start_link args: #{inspect args}"
    id = Keyword.get args, :id, :game
    case GenServer.start_link __MODULE__, args, [name: id] do
      {:error, {:already_started, pid}} ->
        Logger.error "Game already running on: #{inspect pid}"
        {:ok, pid}
      ret ->
        ret
    end
  end

  @impl true
  def init(args) do
     #Logger.info "#{__MODULE__} Initing args: #{inspect args}"

     dictionary_file = Keyword.get args, :dictionary_file, nil
      if dictionary_file == nil do
        throw :no_dictionary_file
      end

      word_length = Keyword.get args, :word_length, nil
       if word_length == nil do
         throw :no_word_length
       end

       number_of_guesses = Keyword.get args, :number_of_guesses, nil
        if number_of_guesses == nil do
          throw :no_number_of_guesses
        end

        even_guesses = rem(number_of_guesses, 2) == 0

     words = case File.read(dictionary_file) do
       {:ok, body}      -> match_words(body, word_length)
       {:error, reason} -> Logger.error "Couldn't read file: #{reason}"
                           []
     end

     pattern = Enum.reduce(1..word_length, "", fn(_x, acc) ->
       acc <> "- "
     end)

    #
    # Register to get a terminate callback when shutting down
    #
    Process.flag(:trap_exit, true)

    state = %State {
      words: words,
      pattern: pattern,
      word_length: word_length,
      guesses: number_of_guesses,
      even_guesses: even_guesses,
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

  def winning_word do
    GenServer.call :game, {:get_winning_word}
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
  def handle_call({:get_winning_word}, _from, %{words: words, even_guesses: even_guesses} = state) do
    # word = if even_guesses do
    #   [h | _t] = words
    #   h
    # else
    #   List.last(words)
    # end
    rand = :random.uniform(length(words)) - 1
    word = Enum.at(words, rand)
    # Logger.info "rand: #{rand}"

    {:reply, word, state}
  end

  @impl true
  def handle_call({:guess, guess}, _from, %{words: words, pattern: pattern, guesses: guesses, guessed: guessed} = state) do

    updated_guessed = case length(guessed) do
      0 -> [guess]
      _ -> guessed ++ [", ", guess]
    end

    map = map_words words, pattern, guess
    {p, w} = Enum.reduce(map, {"", []}, fn({k, v}, {acck, accv}) ->
      if length(accv) < length(v) do
        {k, v}
      else
        {acck, accv}
      end
    end)

    {:reply, length(w), %{state | words: w, pattern: p, guesses: guesses - 1, guessed: updated_guessed}}
  end
  #</editor-fold>


  #<editor-fold desc='Private Methods'>
  defp map_words words, pattern, guess do
    words
    |> Enum.reduce(%{}, fn(x, acc) ->
      word_pattern = make_pattern pattern, x, guess
      case acc[word_pattern] do
        nil -> Map.put(acc, word_pattern, [x])
        v -> Map.put(acc, word_pattern, [x] ++ v)
      end
    end)
  end

  defp match_words contents, length do
    words = contents
    |> String.split("\n", trim: true)

    Enum.filter(words, fn(x) ->
      String.length(x) == length
    end)
  end

  def make_pattern(pattern, word, guess)
  when is_binary(pattern) and is_binary(word) and is_binary(guess) do
    {s, _} = String.graphemes(word)
    |> Enum.reduce({"", pattern <> " "}, fn(c, {acc, p}) ->
      <<head :: binary-size(2)>> <> rest = p
      case c == guess do
        :true -> {acc <> "#{c} ", rest}
        :false -> {acc <> head, rest}
      end
    end)
    String.trim(s)
  end
  #</editor-fold>


  #<editor-fold desc='terminate Functions'>
  # handle the trapped exit call
  @impl true
  def terminate(:shutdown, _state) do
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
