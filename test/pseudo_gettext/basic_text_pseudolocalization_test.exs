defmodule PseudoGettext.BasicTextPseudolocalizationTest do
  use ExUnit.Case, async: true

  require PseudoGettextTestBackend, as: TestBackend

  doctest PseudoGettext.TextPseudolocalization

  test "uses the right locale" do
    # When no locale is set, use the default locale
      assert TestBackend.gettext("Hey!") == "Hey!"
      assert TestBackend.gettext("You are number 1!") == "You are number 1!"

    # When the locale is set, use the pseudolocale
    PseudoGettext.with_locale("en-pseudo_text", fn ->
      assert TestBackend.gettext("Hey!") == "⟪Ȟêÿ~!⟫"
      assert TestBackend.gettext("You are number 1!") == "⟪Ẏøü~ àȓê~ ñüɱƀêȓ~~ 𝟙!⟫"
    end)
  end

  test "pseudolocalized text will never contain ascii letters" do
    PseudoGettext.with_locale("en-pseudo_text", fn ->
      sentence_lowercase = TestBackend.gettext("the quick _brown_ fox jumps over the lazy dog?!.")
      sentence_all_caps = TestBackend.gettext("THE QUICK _BROWN_ FOX JUMPS OVER THE LAZY DOG?!.")
      sentence_all_digits = TestBackend.gettext("0 1 2 3 4 5 6 7 8 9 ?!._")

      sentences = [
        sentence_lowercase,
        sentence_all_caps,
        sentence_all_digits
      ]

      for sentence <- sentences do
        sentence_codepoints = String.codepoints(sentence)

        # Non-alphanumeric characters are preserved
        assert "." in sentence_codepoints
        assert "?" in sentence_codepoints
        assert " " in sentence_codepoints
        assert "_" in sentence_codepoints

        # Alphanumeric characters are replaced by their similar counterparts
        for c <- ?a..?z do
          assert <<c>> not in sentence_codepoints
        end

        for c <- ?0..?9 do
          assert <<c>> not in sentence_codepoints
        end

        # Brackets are present
      assert String.starts_with?(sentence, "⟪")
      assert String.ends_with?(sentence, "⟫")
      end
    end)
  end

  test "pseudolocalized text will never contain ascii digits" do
    PseudoGettext.with_locale("en-pseudo_text", fn ->
      sentence_all_digits = TestBackend.gettext("0 * 1 / 2 * 3 / (4 + 5 - 6) - 7 * 8 * 9")

      sentence_codepoints = String.codepoints(sentence_all_digits)

      # Non-alphanumeric characters are preserved
      assert " " in sentence_codepoints
      assert "+" in sentence_codepoints
      assert "-" in sentence_codepoints
      assert "/" in sentence_codepoints
      assert "*" in sentence_codepoints

      # Alphanumeric characters are replaced by their similar counterparts
      for c <- ?0..?9 do
        assert <<c>> not in sentence_codepoints
      end

      # Brackets are present
      assert String.starts_with?(sentence_all_digits, "⟪")
      assert String.ends_with?(sentence_all_digits, "⟫")
    end)
  end
end
