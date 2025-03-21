module IconHelper
  def icon(name, options = {})
    default_options = {
      class: "icon icon-#{name}",
      width: 24,
      height: 24
    }

    options = default_options.merge(options)

    content_tag :svg, options do
      content_tag :use, nil, "xlink:href": "#icon-#{name}"
    end
  end
end
