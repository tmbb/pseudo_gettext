defmodule PseudoGettext.HtmlPseudolocalization do
  @moduledoc """
  A module to support pseudolocalization of HTML strings.
  """
  import NimbleParsec
  alias PseudoGettext.Common
  alias PseudoGettext.TextPseudolocalization

  # To correctly pseudolocalize HTML, we need to parse the tags
  # and be careful to only apply pseudolocalization to raw text outside
  # of the tags.

  # An HTML tag is basically anything between `<` and `>`.
  # Because HTMl attributes may contain inline CSS and inline JS,
  # it's possible that `<` and `>` can appear inside an HTML tag.
  # We can deal with that, but that requires parsing a non-trivial
  # subset of the HTML standard...
  # This can be done, but it's not a priority right now
  html_tag =
    string("<")
    |> utf8_string([not: ?>], min: 0)
    |> string(">")

  # An HTMl entity is (more or less) an ampersand (`&`) character
  # followed by a number of characters which an be either:
  #   * a decimal or hexadecimal encoding of the unicode codepoint
  #   * a character name (there is a finite number of supported names)
  # The entity reference is usualy but not always terminated by a colon (`;`)

  # Encoding of characters using the decimal and hexadecimal values:
  hex_encoding = times(ascii_char([?0..?9, ?a..?f, ?A..?F]), min: 1)
  decimal_encoding = times(ascii_char([?0..?9]), min: 1)

  entity_names =
    "lib/pseudo_gettext/data/html_entities.txt"
    |> File.read!()
    |> String.split("\n")

  html_entity_named = choice(Enum.map(entity_names, &string/1))

  # Encapsulate the above combinator in a function to reduce compilation time
  # at the cost of being a little slower at runtime
  defparsec(:html_entity_named, html_entity_named)

  # Now, everything together:
  # An HTML entity always starts with a literal ampersand character
  html_entity_codepoint =
    string("&#")
    |> choice([
      # Decimal (no need for a prefix)
      decimal_encoding,
      # Hexadecimal (as indicated by the `x` prefix)
      string("x") |> concat(hex_encoding)
    ])
    # In any case, it is terminated by a semicolon
    |> string(";")

  html_entity =
    choice([
      html_entity_codepoint,
      # Use the parsec and not the combinator to reduce compilation time.
      # Apparently NimbleParsec tries really hard to optimize these choices
      # unless we use the parsec.
      parsec(:html_entity_named)
    ])

  # Text is anything that isn't an HTML tag or an entity
  text = utf8_string([not: ?<, not: ?>, not: ?&], min: 1)

  # Consume a single character as a form of error correction
  malformed = utf8_string([], 1)

  # We'll split the (possibly empty) HTML string into fragments
  # using the combinators above.
  # Only the parts tagged as `:text` will be pseudolocalized.
  html_contents =
    choice([
      tag(html_tag, :html_tag),
      tag(html_entity, :html_entity),
      unwrap_and_tag(text, :text),
      unwrap_and_tag(malformed, :malformed)
    ])
    |> repeat()

  defparsecp(:html_contents, html_contents)

  @doc false
  # This function is mae public (but hidden!) to make it easier to test
  # the very rudimentary HTML "parser".
  def parse_html(text) do
    # This line should never raise an error because
    # our parser will never fail on any string.
    # It something is really strange it will just use
    # the `malformed` combinator and proceed.
    {:ok, fragments, "", _, _, _} = html_contents(text)
    fragments
  end

  # Pseudolocalize the result of each of the combinators above.
  # To get the final string, we just concatenate everything.
  defp pseudolocalize_fragment({:html_tag, iolist}), do: iolist
  defp pseudolocalize_fragment({:html_entity, iolist}), do: iolist
  defp pseudolocalize_fragment({:malformed, iolist}), do: iolist

  defp pseudolocalize_fragment({:text, text}),
    do: TextPseudolocalization.pseudolocalize_fragment(text)

  @doc """
  Apply pseudolocalization to a given HTML string (respecting tags).
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
        which is still legible (for example, `m ??? ??`, `j ??? ??` )
      * Add extra tilde (`~`) characters to words to make them 35% longer.
        as a rule of thumb, one should assume that foreign language strings
        are 35% longer in other languages
      * Surround the string with `"???"` and `"???"` so that you can idenify messages
        that are to big for the containing element (those messages won't be surrounded
        by `"???"` and `"???"`).
      * Other characters (non-latin characters, numbers, punctuation characters, etc.)
        are not touched by the localization process
      * *Respect HTML tags* (tags are preserved by pseudolocalization)
  ## Examples
      iex> alias PseudoGettext.HtmlPseudolocalization
      PseudoGettext.HtmlPseudolocalization
      iex> HtmlPseudolocalization.pseudolocalize("normal text") |> to_string()
      "???????????????~~ ?????????~???"
      iex> HtmlPseudolocalization.pseudolocalize("<a-tag>") |> to_string()
      "???<a-tag>???"
      iex> HtmlPseudolocalization.pseudolocalize("Abbot &amp; Costello") |> to_string()
      "?????????????~ &amp; ????????????????~~???"
      iex> HtmlPseudolocalization.pseudolocalize("Abbot &amp Costello") |> to_string() # entity without semicolon
      "?????????????~ &amp ????????????????~~???"
      iex> HtmlPseudolocalization.pseudolocalize("<strong>Abbot</strong> &amp Costello") |> to_string()
      "???<strong>??????????~</strong> &amp ????????????????~~???"
  """
  def pseudolocalize(string) do
    string
    |> parse_html()
    |> Enum.map(&pseudolocalize_fragment/1)
    |> Common.surround_by_brackets()
  end
end
