defmodule PseudoGettext.Testing do
  defdelegate assert_pseudolocalized_html!(html_text, opts \\ []), to: PseudoGettext.HtmlScraper
end
