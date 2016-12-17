require "colorized_string"

module Formatters
  def print_section(title, items)
    puts "\n", title, items if items.any?
  end

  def random_color
    ColorizedString.colors.sample
  end
end
