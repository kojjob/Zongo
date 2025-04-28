# Helper methods for accessibility features
module AccessibilityHelper
  # Create an accessible icon with proper aria attributes
  # @param icon_name [String] the name of the icon
  # @param text [String] the text to display alongside the icon (also used for screen readers)
  # @param options [Hash] additional options for the icon
  # @option options [String] :class additional CSS classes
  # @option options [Boolean] :hide_text whether to visually hide the text (but keep it for screen readers)
  # @option options [Boolean] :icon_first whether the icon should come before the text
  # @return [String] HTML for the accessible icon
  def accessible_icon(icon_name, text, options = {})
    options = {
      class: '',
      hide_text: false,
      icon_first: true
    }.merge(options)
    
    icon_html = icon(icon_name, class: "#{options[:class]}")
    
    if options[:hide_text]
      # Icon with visually hidden text
      content_tag(:span, class: "icon-with-text #{options[:class]}", "aria-label": text) do
        icon_html + content_tag(:span, text, class: "sr-only")
      end
    else
      # Icon with visible text
      content_tag(:span, class: "icon-with-text #{options[:class]}") do
        if options[:icon_first]
          icon_html + content_tag(:span, text, class: "ml-2")
        else
          content_tag(:span, text, class: "mr-2") + icon_html
        end
      end
    end
  end
  
  # Create an accessible button with proper aria attributes
  # @param text [String] the text to display on the button
  # @param options [Hash] additional options for the button
  # @option options [String] :class additional CSS classes
  # @option options [String] :icon icon name to display alongside the text
  # @option options [Boolean] :icon_first whether the icon should come before the text
  # @option options [String] :type button type (button, submit, reset)
  # @option options [Hash] :data data attributes
  # @option options [String] :aria additional aria attributes
  # @return [String] HTML for the accessible button
  def accessible_button(text, options = {})
    options = {
      class: 'px-4 py-2 bg-primary-600 hover:bg-primary-700 text-white rounded-lg',
      icon: nil,
      icon_first: true,
      type: 'button',
      data: {},
      aria: {}
    }.merge(options)
    
    # Ensure minimum size for touch targets
    options[:class] = "accessible-button #{options[:class]}"
    
    # Set default aria attributes
    aria_attributes = {
      role: 'button'
    }.merge(options[:aria])
    
    button_content = if options[:icon]
      if options[:icon_first]
        icon(options[:icon], class: "mr-2 w-5 h-5") + content_tag(:span, text)
      else
        content_tag(:span, text) + icon(options[:icon], class: "ml-2 w-5 h-5")
      end
    else
      text
    end
    
    content_tag(:button, button_content, 
      class: options[:class],
      type: options[:type],
      data: options[:data],
      aria: aria_attributes
    )
  end
  
  # Create an accessible link with proper aria attributes
  # @param text [String] the text to display on the link
  # @param url [String] the URL to link to
  # @param options [Hash] additional options for the link
  # @option options [String] :class additional CSS classes
  # @option options [String] :icon icon name to display alongside the text
  # @option options [Boolean] :icon_first whether the icon should come before the text
  # @option options [Hash] :data data attributes
  # @option options [String] :aria additional aria attributes
  # @return [String] HTML for the accessible link
  def accessible_link(text, url, options = {})
    options = {
      class: '',
      icon: nil,
      icon_first: true,
      data: {},
      aria: {}
    }.merge(options)
    
    # Set default aria attributes
    aria_attributes = {}.merge(options[:aria])
    
    link_content = if options[:icon]
      if options[:icon_first]
        icon(options[:icon], class: "mr-2 w-5 h-5") + content_tag(:span, text)
      else
        content_tag(:span, text) + icon(options[:icon], class: "ml-2 w-5 h-5")
      end
    else
      text
    end
    
    link_to(link_content, url, 
      class: options[:class],
      data: options[:data],
      aria: aria_attributes
    )
  end
  
  # Create an accessible form label with proper aria attributes
  # @param form [FormBuilder] the form builder object
  # @param field [Symbol] the field to create a label for
  # @param text [String] the text to display on the label
  # @param options [Hash] additional options for the label
  # @option options [Boolean] :required whether the field is required
  # @option options [String] :class additional CSS classes
  # @return [String] HTML for the accessible label
  def accessible_label(form, field, text, options = {})
    options = {
      required: false,
      class: ''
    }.merge(options)
    
    label_class = options[:required] ? "form-required #{options[:class]}" : options[:class]
    
    form.label field, text, class: label_class
  end
  
  # Create an accessible tooltip
  # @param text [String] the text to display in the tooltip
  # @param content [String] the content to wrap with the tooltip
  # @param options [Hash] additional options for the tooltip
  # @option options [String] :class additional CSS classes
  # @option options [String] :position position of the tooltip (top, bottom, left, right)
  # @return [String] HTML for the accessible tooltip
  def accessible_tooltip(text, content, options = {})
    options = {
      class: '',
      position: 'top'
    }.merge(options)
    
    content_tag(:div, class: "tooltip-wrapper #{options[:class]}") do
      content_tag(:div, text, class: "tooltip-content tooltip-#{options[:position]}", role: "tooltip") +
      content
    end
  end
  
  # Create an accessible table with proper aria attributes
  # @param headers [Array] the table headers
  # @param rows [Array] the table rows
  # @param options [Hash] additional options for the table
  # @option options [String] :class additional CSS classes
  # @option options [String] :caption table caption
  # @option options [Boolean] :responsive whether the table should be responsive
  # @return [String] HTML for the accessible table
  def accessible_table(headers, rows, options = {})
    options = {
      class: '',
      caption: nil,
      responsive: true
    }.merge(options)
    
    table_class = "accessible-table #{options[:class]}"
    
    table_html = content_tag(:table, class: table_class) do
      table_content = ""
      
      # Add caption if provided
      if options[:caption]
        table_content += content_tag(:caption, options[:caption])
      end
      
      # Add headers
      table_content += content_tag(:thead) do
        content_tag(:tr) do
          headers.map { |header| content_tag(:th, header, scope: "col") }.join.html_safe
        end
      end
      
      # Add rows
      table_content += content_tag(:tbody) do
        rows.map do |row|
          content_tag(:tr) do
            row.map.with_index do |cell, index|
              if index == 0
                content_tag(:th, cell, scope: "row")
              else
                content_tag(:td, cell)
              end
            end.join.html_safe
          end
        end.join.html_safe
      end
      
      table_content.html_safe
    end
    
    if options[:responsive]
      content_tag(:div, table_html, class: "overflow-x-auto")
    else
      table_html
    end
  end
end
