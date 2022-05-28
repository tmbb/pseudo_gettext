defmodule PseudoGettext.Common do
  @moduledoc """
  Common functions for modules that implement pseudolocalization of text
  in several markup formats.
  From [Wikipedia](https://en.wikipedia.org/wiki/Pseudolocalization):

  > Pseudolocalization (or pseudo-localization) is a software testing method
  > used for testing internationalization aspects of software.
  > Instead of translating the text of the software into a foreign language,
  > as in the process of localization, the textual elements of an application
  > are replaced with an altered version of the original language.
  >
  > These specific alterations make the original words appear readable,
  > but include the most problematic characteristics of the world's languages:
  > varying length of text or characters, language direction,
  > fit into the interface and so on.
  """

  alias PseudoGettext.Common
  import NimbleParsec
  # Strings in other languages are assumed to be ~35% longer than in English
  @language_expansion 0.35
  # Pad the string with extra characters to simulate ~35% longer words
  @padding_characters "~"

  # Create a parsec that will distinguish words from everything else
  # so that we only expand the words and so that we handle punctuation
  # in a natural way.
  #
  # We prefer "word~." instead of "word.~" (that's why we won't split blindly on whitespace)

  non_word_characters = String.to_charlist("_.!?,;:«»\"`()[]{} \n\f\r")
  word_characters = Enum.map(non_word_characters, fn c -> {:not, c} end)

  maybe_empty_non_word_char_sequence = utf8_string(non_word_characters, min: 0)
  # right = utf8_string(non_word_characters, min: 0)
  word_char_sequence = utf8_string(word_characters, min: 1)

  head =
    unwrap_and_tag(maybe_empty_non_word_char_sequence, :non_word)
    |> tag(:chunk)

  word =
    unwrap_and_tag(word_char_sequence, :word)
    |> unwrap_and_tag(maybe_empty_non_word_char_sequence, :non_word)
    |> tag(:chunk)

  defparsecp(:chunk_parsec, head |> repeat(word))


  defp split_into_chunks(text) do
    {:ok, words, "", _, _, _} = chunk_parsec(text)
    words
  end

  @doc """
  Pseudolocalizes a word, which can include other non-word characters.
  Such characters are handled intelligently.
  ## Examples:
      iex> alias PseudoGettext.Common
      PseudoGettext.Common

      iex> Common.pseudolocalize_word("text") |> to_string()
      "ťêẋť~"

      iex> Common.pseudolocalize_word("text!") |> to_string()
      "ťêẋť~!"

      iex> Common.pseudolocalize_word("(text!)") |> to_string()
      "(ťêẋť~!)"

      iex> Common.pseudolocalize_word("") |> to_string()
      ""
  """
  def pseudolocalize_chunk({:chunk, parts}) do
    word = Keyword.get(parts, :word, nil)
    non_word = Keyword.get(parts, :non_word, "")

    localized_word =
      case word do
        nil ->
          ""

        text ->
          length = String.length(text)
          nr_of_extra_characters = floor(length * @language_expansion)
          extra_characters = String.duplicate(@padding_characters, nr_of_extra_characters)

          new_graphemes =
            for grapheme <- String.graphemes(text) do
              Common.convert_grapheme(grapheme)
            end

          [new_graphemes, extra_characters]
      end

    [localized_word, non_word]
  end

  def pseudolocalize_text(text) do
    original_words = split_into_chunks(text)
    Enum.map(original_words, &pseudolocalize_chunk/1)
  end

  @doc """
  Converts a single grapheme (not a unicode codepoint!) into a localized version.
  You probably don't want to use this directly unless you want to implement your
  custom pseudolocalization function that deals with things like HTML tags
  or other special markup.
  ## Examples
      iex> alias PseudoGettext.Common
      PseudoGettext.Common
      iex> Common.convert_grapheme("A") |> to_string()
      "Å"
      iex> Common.pseudolocalize_word("D") |> to_string()
      "Đ"
      iex> Common.pseudolocalize_word("f") |> to_string()
      "ƒ"
  """
  def convert_grapheme(g) do
    case g do
      # Upper case
      "A" -> "Å"
      "B" -> "Ɓ"
      "C" -> "Ċ"
      "D" -> "Đ"
      "E" -> "Ȅ"
      "F" -> "Ḟ"
      "G" -> "Ġ"
      "H" -> "Ȟ"
      "I" -> "İ"
      "J" -> "Ĵ"
      "K" -> "Ǩ"
      "L" -> "Ĺ"
      "M" -> "Ṁ"
      "N" -> "Ñ"
      "O" -> "Ò"
      "P" -> "Ƥ"
      "Q" -> "Ꝗ"
      "R" -> "Ȓ"
      "S" -> "Ș"
      "T" -> "Ť"
      "U" -> "Ü"
      "V" -> "Ṽ"
      "W" -> "Ẃ"
      "X" -> "Ẍ"
      "Y" -> "Ẏ"
      "Z" -> "Ž"
      # Lower case
      "a" -> "à"
      "b" -> "ƀ"
      "c" -> "ċ"
      "d" -> "đ"
      "e" -> "ê"
      "f" -> "ƒ"
      "g" -> "ğ"
      "h" -> "ȟ"
      "i" -> "ı"
      "j" -> "ǰ"
      "k" -> "ǩ"
      "l" -> "ĺ"
      "m" -> "ɱ"
      "n" -> "ñ"
      "o" -> "ø"
      "p" -> "ƥ"
      "q" -> "ʠ"
      "r" -> "ȓ"
      "s" -> "š"
      "t" -> "ť"
      "u" -> "ü"
      "v" -> "ṽ"
      "w" -> "ẁ"
      "x" -> "ẋ"
      "y" -> "ÿ"
      "z" -> "ź"
      # Digits
      "0" -> "𝟘"
      "1" -> "𝟙"
      "2" -> "𝟚"
      "3" -> "𝟛"
      "4" -> "𝟜"
      "5" -> "𝟝"
      "6" -> "𝟞"
      "7" -> "𝟟"
      "8" -> "𝟠"
      "9" -> "𝟡"
      # Other characters are returned as they are
      other -> other
    end
  end

  def surround_by_brackets(iolist) do
    ["⟪", iolist, "⟫"]
  end

  def not_pseudolocalized?(c) do
    (c in ?a..?z) or (c in ?A..?Z) or (c in ?0..?9)
  end

  def validate_pseudolocalized(text) do
    unicode_characters = to_charlist(text)
    errors =
      for {char, index} <- Enum.with_index(unicode_characters, 0), not_pseudolocalized?(char) do
        {<< char :: utf8 >>, index}
      end

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end
end
