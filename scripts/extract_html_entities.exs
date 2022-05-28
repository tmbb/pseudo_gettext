defmodule PseudoGettext.ExtractHtmlEntities do
  def run() do

    entity_names =
      "lib/pseudo_gettext/data/html_entities.json"
      |> File.read!()
      |> Jason.decode!()
      |> Map.keys()

    # We sort the list in reverse because some entity names are prefixes of other entiry names.
    # The most obvious case is entity names such as `&amp`, which might or migh not
    # end in a semicolon.
    # By ordering all entity names in a decreasing lexicographic ordering,
    # we make sure that (for example) `&amp` will be matched after `&amp;`
    reversed_entity_names =
      entity_names
      |> Enum.sort()
      |> Enum.reverse()

    iolist = Enum.intersperse(reversed_entity_names, "\n")
    File.write!("lib/pseudo_gettext/data/html_entities.txt", iolist)
  end
end

PseudoGettext.ExtractHtmlEntities.run()
