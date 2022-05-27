defmodule PseudoGettext.HtmlPseudolocalizationTesterTest do
  use ExUnit.Case, async: true

  import PseudoGettext.Testing

  require PseudoGettextTestBackend, as: TestBackend

  alias PseudoGettext.PseudolocalizationAssertionError


  test "abc" do
    html = """
      <p class="paragraph" id="par1">
        <span class="bold">
          this is <b>not</b> pseudolocalized
        </span>
      </p>
      """

    localized_html =
      PseudoGettext.with_locale("en-pseudo_html", fn ->
        TestBackend.gettext("""
          <p class="paragraph" id="par1">
            <span class="bold">
              this is <b>not</b> pseudolocalized
            </span>
          </p>
          """)
      end)

    # HTML that hasn't been localized fails
    assert_raise PseudolocalizationAssertionError, fn ->
      assert_pseudolocalized_html!(html)
    end

    # HTML that hasn't been localized succeeds
    assert_pseudolocalized_html!(localized_html)
  end
end
