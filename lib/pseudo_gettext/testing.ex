defmodule PseudoGettext.Testing do
  alias PseudoGettext.HtmlScraper

  def assert_pseudolocalized_html!(html_text, opts \\ []) do
    HtmlScraper.assert_pseudolocalized_html!(html_text, opts)
  end
end
