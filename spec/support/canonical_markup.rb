# frozen_string_literal: true

# Canonical, diff-friendly renderings of captured DOM for the comparison
# specs: one line per element (attributes sorted) or run of text, indented by
# depth. The canonical form targets structure over incidentals:
#
# * id-valued attributes (`id`, `for`) and id-list references
#   (`aria-labelledby`, `aria-describedby`) are mapped to tokens in encounter
#   order — a comparison checks that elements are wired to each other the
#   same way, not that the generated ids match
# * `name` is tokenised through its own table, so inputs sharing a name still
#   share a token while the value itself is ignored
# * non-blank `value`s and `src` urls are tokenised: two captures never hold
#   the same blob
# * whitespace in attribute values and text is collapsed
#
# Boolean attributes are NOT normalised: HTML treats `hidden=""` and
# `hidden="hidden"` alike, but `hidden` is enumerated (`until-found` is a
# distinct state) and every forgiven difference is a hole in the drift net —
# implementations should match the reference spelling instead.
module CanonicalMarkup
  # Canonicalise one or more elements against a shared token table.
  def canonical_markup(*nodes)
    maps = Hash.new do |hash, kind|
      hash[kind] = Hash.new { |map, value| map[value] = "[#{kind}-#{map.size + 1}]" }
    end

    nodes.compact.flat_map { |node| canonical_lines(node, maps) }.join("\n")
  end

  private

  def canonical_lines(node, maps, depth = 0)
    indent     = "  " * depth
    attributes = node.attribute_nodes.sort_by(&:name).map do |attribute|
      canonical_attribute(attribute, maps)
    end

    lines = ["#{indent}<#{[node.name, *attributes].join(' ')}>"]
    node.children.each do |child|
      if child.element?
        lines.concat(canonical_lines(child, maps, depth + 1))
      elsif child.text? && !child.text.squish.empty?
        lines << "#{indent}  #{child.text.squish}"
      end
    end

    lines
  end

  def canonical_attribute(attribute, maps)
    %(#{attribute.name}="#{canonical_value(attribute, maps)}")
  end

  def canonical_value(attribute, maps)
    case attribute.name
    when "id", "for" then maps["id"][attribute.value]
    when "aria-labelledby", "aria-describedby"
      attribute.value.split.map { |id| maps["id"][id] }.join(" ")
    when "name" then maps["name"][attribute.value]
    when "value" then attribute.value.empty? ? "" : "[value]"
    when "src" then "[url]"
    else attribute.value.squish
    end
  end
end
