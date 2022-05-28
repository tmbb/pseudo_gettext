defmodule PseudoGettext.TextPseudolocalization do
  @moduledoc """
  A module to support pseudolocalization.
  """
  alias PseudoGettext.Common

  @doc """
  Apply pseudolocalization to a given string.
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

  This pseudolocalization function does the following:

  * Replace each latin character with a slightly modified version,
    which is still legible (for example, `m → ɱ`, `j → ǰ`). This allows
    the programmer and users to visually distinguish text that has been
    internationalized (i.e. wrapped in a `gettext` call) from text that
    hasn't been internationalized. The fact that we convert characters
    into characters that are visually similar means that the text remains
    readable.

  * Replace arabic numerals (i.e. latin digits) as we did above.
    The goal is the same: to have arabic numerals that are visually
    distinct but understandable.

  * Add extra tilde (`~`) characters to words to make them ~35% longer.
    This allows us to identify UI elements that are too inflexible for
    languages that may take up more space than English.
    As a rule of thumb, one should assume that foreign language strings
    are 35% longer in other languages.

  * Surround the string with `"⟪"` and `"⟫"` so that you can idenify messages
    that are to big for the containing element (those messages will be clipped
    and the text won't be surrounded by `"⟪"` and `"⟫"` on both sides).

  * Other characters (non-latin characters, punctuation characters, etc.)
    are not touched by the localization process.

  This function doesn't respect any kind of markup that uses words, like HTML, XML and others.
  If you need pseudolocalization of such strings, you must implement your own function.

  ## Examples

      iex> alias PseudoGettext.TextPseudolocalization
      PseudoGettext.TextPseudolocalization

      iex> TextPseudolocalization.pseudolocalize("One") |> to_string()
      "⟪Òñê~⟫"

      ex> TextPseudolocalization.pseudolocalize("Two") |> to_string()
      "⟪Ťẁø~⟫"

      iex> TextPseudolocalization.pseudolocalize("This is an example sentence.") |> to_string()
      "⟪Ťȟıš~ ıš àñ êẋàɱƥĺê~~ šêñťêñċê~~.⟫"

      iex> TextPseudolocalization.pseudolocalize("sesquipedalian") |> to_string()
      "⟪šêšʠüıƥêđàĺıàñ~~~~⟫"

      iex> TextPseudolocalization.pseudolocalize("With punctuation.") |> to_string()
      "⟪Ẃıťȟ~ ƥüñċťüàťıøñ~~~.⟫"

      iex> TextPseudolocalization.pseudolocalize("(parenthesis)") |> to_string()
      "⟪(ƥàȓêñťȟêšıš~~~)⟫"

      iex> TextPseudolocalization.pseudolocalize("the quick brown fox jumps over the lazy dog.") |> to_string()
      "⟪ťȟê~ ʠüıċǩ~ ƀȓøẁñ~ ƒøẋ~ ǰüɱƥš~ øṽêȓ~ ťȟê~ ĺàźÿ~ đøğ~.⟫"

      iex> TextPseudolocalization.pseudolocalize("THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.") |> to_string()
      "⟪ŤȞȄ~ ꝖÜİĊǨ~ ƁȒÒẂÑ~ ḞÒẌ~ ĴÜṀƤȘ~ ÒṼȄȒ~ ŤȞȄ~ ĹÅŽẎ~ ĐÒĠ~.⟫"
  """
  def pseudolocalize(text) do
    text
    |> pseudolocalize_fragment()
    |> Common.surround_by_brackets()
  end

  def pseudolocalize_as_binary(text) do
    text |> pseudolocalize() |> to_string()
  end

  def pseudolocalize_fragment(string) do
    Common.pseudolocalize_text(string)
  end
end
