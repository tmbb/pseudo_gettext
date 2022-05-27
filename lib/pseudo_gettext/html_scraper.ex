defmodule PseudoGettext.HtmlScraper do
  @moduledoc false

  alias PseudoGettext.Common
  alias PseudoGettext.PseudolocalizationAssertionError

  def scrape_text(elements, user_visible_attrs) when is_list(elements) do
    elements
    |> Enum.map(fn element -> scrape_text_helper(element, [], user_visible_attrs) end)
    |> List.flatten()
    |> Enum.map(&reverse_path/1)
    |> Enum.map(fn {meta, text} -> {meta, String.replace(text, "\r\n", "\n")} end)
  end

  def scrape_text(element, user_visible_attrs) do
    elements = List.wrap(element)
    scrape_text(elements, user_visible_attrs)
  end


  defp scrape_text_helper({tag, attrs, children}, path_to_root, user_visible_attrs) do
    user_visible_attrs_in_this_tag =
      for {attr, value} <- attrs, attr in user_visible_attrs do
        {{:attr, [{tag, attrs} | path_to_root], attr}, value}
      end

    children_text =
      for child <- children do
        scrape_text_helper(child, [{tag, attrs}| path_to_root], user_visible_attrs)
      end

    [user_visible_attrs_in_this_tag | children_text]
  end

  defp scrape_text_helper(text, path_to_root, _user_visible_attrs) when is_binary(text) do
    {{:text, path_to_root}, text}
  end

  defp reverse_path({{:text, path}, text}), do: {{:text, Enum.reverse(path)}, text}
  defp reverse_path({{:attr, path, attr}, text}), do: {{:attr, Enum.reverse(path), attr}, text}

  defp class_selector(nil), do: ""

  defp class_selector({"class", ""}), do: ""

  defp class_selector({"class", classes_text}) do
    classes = String.split(classes_text)
    "." <> Enum.join(classes, ".")
  end

  defp id_selector(nil), do: ""

  defp id_selector({"id", ""}), do: ""

  defp id_selector({"id", id}), do: "##{id}"

  def show_path_component({tag, attrs}) do
    maybe_id = Enum.find(attrs, fn {key, _val} -> key == "id" end)
    maybe_class = Enum.find(attrs, fn {key, _val} -> key == "class" end)

    tag <> class_selector(maybe_class) <> id_selector(maybe_id)
  end

  def show_path(path) do
    components = Enum.map(path, &show_path_component/1)
    Enum.join(components, " > ")
  end

  def show_path_to_text({{:text, []}, text}) do
    inspect(text)
  end

  def show_path_to_text({{:text, path}, text}) do
    "#{show_path(path)} #{inspect(text)}"
  end

  def show_path_to_text({{:attr, path, attr}, text}) do
    "#{show_path(path)}[#{attr}=#{inspect(text)}]"
  end

  def validate_pseudolocalized_html(html_text, opts \\ []) do
    user_visible_attrs = Keyword.get(opts, :user_visible_attrs, ["title", "alt", "placeholder"])
    {:ok, dom} = Floki.parse_fragment(html_text)
    text_fragments = scrape_text(dom, user_visible_attrs)
    invalid =
      text_fragments
      |> Enum.map(&validate_text_fragment/1)
      |> Enum.reject(fn {a, _b} -> a == :ok end)

    invalid
  end

  def validate_text_fragment({metadata, text}) do
    case Common.validate_pseudolocalized(text) do
      :ok -> {:ok, {metadata, text}}
      {:error, _errors} = validation -> {validation, {metadata, text}}
    end
  end

  def assert_pseudolocalized_html!(html_text, opts \\ []) do
    invalid = validate_pseudolocalized_html(html_text, opts)

    if invalid == [] do
      :ok
    else
      list =
        invalid
        |> Enum.map(fn {_validation, value} -> "  • " <> show_path_to_text(value) end)
        |> Enum.join("\n\n")

      message = """

      The text in the following HTML elements is not properly internationalized:

      #{list}

      """

      raise PseudolocalizationAssertionError, message
    end
  end
end
