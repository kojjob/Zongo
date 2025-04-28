# Accessibility Guide

This document outlines the accessibility features and best practices implemented in the Ghana Super App to ensure compliance with WCAG 2.1 AA standards.

## Table of Contents

1. [Introduction](#introduction)
2. [Accessibility Features](#accessibility-features)
3. [Keyboard Navigation](#keyboard-navigation)
4. [Screen Reader Support](#screen-reader-support)
5. [Focus Management](#focus-management)
6. [Color and Contrast](#color-and-contrast)
7. [Responsive Design](#responsive-design)
8. [Accessibility Components](#accessibility-components)
9. [Testing](#testing)
10. [Resources](#resources)

## Introduction

The Ghana Super App is committed to providing an accessible experience for all users, including those with disabilities. This guide documents the accessibility features and best practices implemented in the application.

## Accessibility Features

The following accessibility features have been implemented:

- **Skip Links**: Allow keyboard users to bypass navigation and jump directly to main content
- **ARIA Attributes**: Proper ARIA roles, states, and properties for interactive elements
- **Keyboard Navigation**: Full keyboard support for all interactive elements
- **Focus Management**: Visible focus indicators and proper focus management
- **Screen Reader Announcements**: Live regions for dynamic content updates
- **High Contrast Mode**: Enhanced visual contrast for users with low vision
- **Reduced Motion**: Option to minimize animations for users with vestibular disorders
- **Text Resizing**: Support for text resizing without breaking layouts
- **Accessible Forms**: Properly labeled form controls with error messages
- **Accessible Modals**: Properly implemented modal dialogs with focus trapping
- **Accessible Tables**: Properly structured tables with headers and captions
- **Accessible Cards**: Properly structured card components with proper focus management

## Keyboard Navigation

All interactive elements in the application are accessible via keyboard:

- **Tab**: Navigate between focusable elements
- **Enter/Space**: Activate buttons, links, and other interactive elements
- **Arrow Keys**: Navigate within components like tabs, dropdowns, and menus
- **Escape**: Close modals, dropdowns, and other overlays
- **Home/End**: Jump to the first/last item in a list or navigation

### Tab Components

Tab components support the following keyboard interactions:

- **Tab**: Move focus to the active tab
- **Arrow Keys**: Navigate between tabs
- **Home/End**: Jump to the first/last tab
- **Enter/Space**: Activate the focused tab
- **Escape**: Exit the tab component

## Screen Reader Support

The application includes the following features for screen reader users:

- **Semantic HTML**: Proper use of HTML5 semantic elements
- **ARIA Landmarks**: Proper use of ARIA landmark roles
- **Alternative Text**: Descriptive alt text for images
- **Form Labels**: Properly associated labels for form controls
- **Live Regions**: Announcements for dynamic content updates
- **Status Messages**: Accessible status messages for form submissions and other actions
- **Skip Links**: Allow screen reader users to bypass navigation

## Focus Management

The application implements proper focus management:

- **Visible Focus Indicators**: High-visibility focus styles for all interactive elements
- **Focus Trapping**: Proper focus trapping for modals and other overlays
- **Focus Restoration**: Proper focus restoration when closing modals and other overlays
- **Logical Tab Order**: Logical and predictable tab order for all pages

## Color and Contrast

The application meets WCAG 2.1 AA contrast requirements:

- **Text Contrast**: Minimum 4.5:1 contrast ratio for normal text
- **Large Text Contrast**: Minimum 3:1 contrast ratio for large text
- **UI Component Contrast**: Minimum 3:1 contrast ratio for UI components
- **Focus Indicators**: High-visibility focus indicators
- **Color Independence**: Information is not conveyed by color alone

## Responsive Design

The application is designed to be accessible on all devices:

- **Responsive Layouts**: Adapts to different screen sizes
- **Touch Targets**: Minimum 44x44px touch targets for mobile devices
- **Zoom Support**: Supports browser zoom up to 400%
- **Orientation Support**: Works in both portrait and landscape orientations
- **Text Resizing**: Supports text resizing without breaking layouts

## Accessibility Components

The application includes the following accessible components:

### Skip Links

Skip links allow keyboard users to bypass navigation and jump directly to main content:

```erb
<%= render 'shared/skip_links' %>
```

### Accessible Modal

Accessible modal dialogs with proper focus management:

```erb
<%= render 'shared/accessible_modal',
  id: 'my-modal',
  title: 'Modal Title',
  description: 'Modal description',
  size: 'md',
  close_button: true,
  footer: true,
  footer_content: content_tag(:div, class: 'flex justify-end space-x-3') do
    button_tag('Cancel', type: 'button', class: 'btn-secondary', data: { action: 'accessibility#closeModal' }) +
    button_tag('Save', type: 'button', class: 'btn-primary')
  end do %>
  <!-- Modal content goes here -->
<% end %>
```

### Accessible Form Fields

Accessible form fields with proper labels and error messages:

```erb
<%= render 'shared/accessible_form_field',
  form: form,
  field: :email,
  label: 'Email Address',
  type: 'email',
  required: true,
  help_text: 'We will never share your email with anyone else.',
  placeholder: 'Enter your email',
  autocomplete: 'email'
%>
```

### Accessible Tables

Accessible tables with proper headers and captions:

```erb
<%= render 'shared/accessible_table',
  caption: 'User List',
  headers: ['Name', 'Email', 'Role', 'Actions'],
  rows: @users.map { |user| [
    user.name,
    user.email,
    user.role,
    link_to('Edit', edit_user_path(user), class: 'btn-sm btn-primary')
  ]},
  responsive: true,
  striped: true,
  bordered: false,
  hover: true,
  compact: false,
  class: 'my-custom-class',
  id: 'users-table',
  empty_message: 'No users found'
%>
```

### Accessible Cards

Accessible card components with proper focus management:

```erb
<%= render 'shared/accessible_card',
  title: 'Card Title',
  subtitle: 'Card Subtitle',
  image: 'path/to/image.jpg',
  image_alt: 'Description of image',
  footer: true,
  footer_content: content_tag(:div, 'Footer content'),
  header_actions: content_tag(:div, link_to('Action', '#', class: 'btn-sm btn-primary')),
  class: 'my-custom-class',
  id: 'my-card',
  clickable: true,
  clickable_url: user_path(@user),
  hover_effect: true,
  shadow: true,
  border: true
do %>
  <!-- Card content goes here -->
<% end %>
```

### Accessible Tabs

Accessible tab components with proper keyboard navigation:

```erb
<%= render 'shared/accessible_tabs',
  tabs: [
    {
      id: 'tab1',
      label: 'Tab 1',
      content: render('tab1_content')
    },
    {
      id: 'tab2',
      label: 'Tab 2',
      content: render('tab2_content')
    }
  ],
  active_tab: 'tab1',
  style: 'bordered',
  orientation: 'horizontal',
  class: 'my-custom-class',
  id: 'my-tabs',
  persist: true,
  persist_key: 'my_tabs_active_tab'
%>
```

### Accessibility Helper Methods

The application includes the following accessibility helper methods:

```ruby
# Create an accessible icon with proper aria attributes
accessible_icon(icon_name, text, options = {})

# Create an accessible button with proper aria attributes
accessible_button(text, options = {})

# Create an accessible link with proper aria attributes
accessible_link(text, url, options = {})

# Create an accessible form label with proper aria attributes
accessible_label(form, field, text, options = {})

# Create an accessible tooltip
accessible_tooltip(text, content, options = {})

# Create an accessible table with proper aria attributes
accessible_table(headers, rows, options = {})
```

## Testing

The application should be tested for accessibility using the following methods:

- **Automated Testing**: Use tools like axe, WAVE, or Lighthouse
- **Keyboard Testing**: Test all functionality using only the keyboard
- **Screen Reader Testing**: Test with screen readers like NVDA, JAWS, or VoiceOver
- **Manual Testing**: Test with real users with disabilities

## Resources

- [Web Content Accessibility Guidelines (WCAG) 2.1](https://www.w3.org/TR/WCAG21/)
- [WAI-ARIA Authoring Practices](https://www.w3.org/TR/wai-aria-practices-1.1/)
- [MDN Web Docs: Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [A11y Project](https://www.a11yproject.com/)
- [Inclusive Components](https://inclusive-components.design/)
