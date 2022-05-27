defmodule PseudoGettext do
  alias PseudoGettext.HtmlPseudolocalization
  alias PseudoGettext.TextPseudolocalization

  def set_global_pseudo_locale(locale) do
    Application.put_env(:pseudo_gettext, :locale, locale)
  end

  def get_global_pseudo_locale() do
    Application.get_env(:pseudo_gettext, :locale, nil)
  end

  @doc false
  def get_locale() do
    case get_global_pseudo_locale() do
      nil ->
        Gettext.get_locale()

      locale ->
        locale
    end
  end

  def with_locale(locale, fun) do
    old_locale = Gettext.get_locale()
    Gettext.put_locale(locale)
    result = fun.()
    Gettext.put_locale(old_locale)

    result
  end

  @doc false
  def maybe_pseudolocalize(text) do
    case get_locale() do
      "en-pseudo_text" ->
        iodata = TextPseudolocalization.pseudolocalize(text)
        IO.iodata_to_binary(iodata)

      "en-pseudo_html" ->
        iodata = HtmlPseudolocalization.pseudolocalize(text)
        IO.iodata_to_binary(iodata)

      _ ->
        text
    end
  end

  @doc false
  defmacro __using__(opts) do
    hidden_gettext_backend = Module.concat(__CALLER__.module, "HiddenGettextBackend")

    hidden_gettext_backend_contents =
      quote do
        @moduledoc false
        use Gettext, unquote(opts)
      end

    Module.create(hidden_gettext_backend, hidden_gettext_backend_contents, __ENV__)

    quote do
      # Ugly hack in order to be able to access the hidden_gettext_backend module
      # inside quoted expressions inside this quoted expression.
      # This hack doesn't seeem to cause any problems, though.
      Module.put_attribute(__MODULE__, :hidden_gettext_backend, unquote(hidden_gettext_backend))

      # Nasty behaviour on the part of Gettext!
      #
      # The functions:
      #
      #   * __gettext__(arg)
      #   * lgettext(locale, domain, msgctxt \\ nil, msgid, bindings)
      #   * lngettext(locale, domain, msgctxt \\ nil, msgid, msgid_plural, n, bindings)
      #
      # are part of the default Gettext backend's public API but they aren't documented
      # as part of the behaviour.

      @doc false
      def __gettext__(arg) do
        unquote(hidden_gettext_backend).__gettext__(arg)
      end

      @doc false
      defdelegate lgettext(locale, domain, msgctxt \\ nil, msgid, bindings), to: unquote(hidden_gettext_backend)

      @doc false
      defdelegate lngettext(locale, domain, msgctxt \\ nil, msgid, msgid_plural, n, bindings), to: unquote(hidden_gettext_backend)

      # These are macros that expand into other macros and post-process the macro's result at runtime.
      # We must require the module
      defmacro dgettext(domain, msgid) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dgettext(unquote(domain), unquote(msgid))
            )
          )
        end
      end

      defmacro dgettext(domain, msgid, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dgettext(
                unquote(domain),
                unquote(msgid),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro dgettext_noop(domain, msgid) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dgettext_noop(domain, msgid)
            )
          )
        end
      end

      defmacro dngettext(domain, msgid, msgid_plural, n) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dngettext(
                unquote(domain),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n)
              )
            )
          )
        end
      end

      defmacro dngettext(domain, msgid, msgid_plural, n, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dngettext(
                unquote(domain),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro dngettext_noop(domain, msgid, msgid_plural) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dngettext_noop(
                unquote(domain),
                unquote(msgid),
                unquote(msgid_plural)
              )
            )
          )
        end
      end

      defmacro dpgettext(domain, msgctxt, msgid) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dpgettext(
                unquote(domain),
                unquote(msgctxt),
                unquote(msgid)
              )
            )
          )
        end
      end

      defmacro dpgettext(domain, msgctxt, msgid, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dpgettext(
                unquote(domain),
                unquote(msgctxt),
                unquote(msgid),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro dpngettext(domain, msgctxt, msgid, msgid_plural, n) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dpngettext(
                unquote(domain),
                unquote(msgctxt),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n)
              )
            )
          )
        end
      end

      defmacro dpngettext(domain, msgctxt, msgid, msgid_plural, n, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).dpngettext(
                unquote(domain),
                unquote(msgctxt),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro gettext(msgid) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).gettext(unquote(msgid))
            )
          )
        end
      end

      defmacro gettext(msgid, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).gettext(unquote(msgid), unquote(bindings))
            )
          )
        end
      end

      defmacro gettext_comment(comment) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).gettext_comment(unquote(comment))
            )
          )
        end
      end

      defmacro gettext_noop(msgid) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).gettext_noop(unquote(msgid))
            )
          )
        end
      end

      defmacro handle_missing_bindings(t, binary) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).handle_missing_bindings(unquote(t), unquote(binary))
            )
          )
        end
      end

      defmacro handle_missing_plural_translation(locale, domain, msgid, msgid_plural, n, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).handle_missing_plural_translation(
                unquote(locale),
                unquote(domain),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro handle_missing_translation(locale, domain, msgid, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).handle_missing_translation(
                unquote(locale),
                unquote(domain),
                unquote(msgid),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro ngettext(msgid, msgid_plural, n) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).ngettext(
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n)
              )
            )
          )
        end
      end

      defmacro ngettext(msgid, msgid_plural, n, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).ngettext(
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro ngettext_noop(msgid, msgid_plural) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).ngettext_noop(msgid, msgid_plural)
            )
          )
        end
      end

      defmacro pgettext(msgctxt, msgid) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).pgettext(unquote(msgctxt), unquote(msgid))
            )
          )
        end
      end

      defmacro pgettext(msgctxt, msgid, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).pgettext(
                unquote(msgctxt),
                unquote(msgid),
                unquote(bindings)
              )
            )
          )
        end
      end

      defmacro pngettext(msgctxt, msgid, msgid_plural, n) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).pngettext(
                unquote(msgctxt),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n)
              )
            )
          )
        end
      end

      defmacro pngettext(msgctxt, msgid, msgid_plural, n, bindings) do
        quote do
          (
            require unquote(@hidden_gettext_backend)
            PseudoGettext.maybe_pseudolocalize(
              unquote(@hidden_gettext_backend).pngettext(
                unquote(msgctxt),
                unquote(msgid),
                unquote(msgid_plural),
                unquote(n),
                unquote(bindings)
              )
            )
          )
        end
      end
    end
  end
end
