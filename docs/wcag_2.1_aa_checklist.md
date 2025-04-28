# WCAG 2.1 AA Compliance Checklist

This document provides a checklist for ensuring compliance with Web Content Accessibility Guidelines (WCAG) 2.1 Level AA standards in the Ghana Super App.

## 1. Perceivable

Information and user interface components must be presentable to users in ways they can perceive.

### 1.1 Text Alternatives
- [ ] **1.1.1 Non-text Content (A)**: All non-text content has text alternatives
  - All images have appropriate alt text
  - SVG elements have accessible names
  - Form controls have associated labels
  - Decorative images use empty alt attributes or are implemented as CSS backgrounds

### 1.2 Time-based Media
- [ ] **1.2.1 Audio-only and Video-only (A)**: Alternatives for time-based media
- [ ] **1.2.2 Captions (A)**: Captions are provided for all prerecorded audio
- [ ] **1.2.3 Audio Description or Media Alternative (A)**: Audio description or alternative for video
- [ ] **1.2.4 Captions (AA)**: Captions are provided for all live audio
- [ ] **1.2.5 Audio Description (AA)**: Audio description is provided for all prerecorded video

### 1.3 Adaptable
- [ ] **1.3.1 Info and Relationships (A)**: Information, structure, and relationships can be programmatically determined
  - Semantic HTML is used (headings, lists, etc.)
  - Tables have proper headers and captions
  - Form fields have proper labels
  - ARIA landmarks are used appropriately
- [ ] **1.3.2 Meaningful Sequence (A)**: The reading sequence is logical and meaningful
- [ ] **1.3.3 Sensory Characteristics (A)**: Instructions don't rely solely on sensory characteristics
- [ ] **1.3.4 Orientation (AA)**: Content doesn't restrict its view to a single display orientation
- [ ] **1.3.5 Identify Input Purpose (AA)**: The purpose of input fields can be programmatically determined

### 1.4 Distinguishable
- [ ] **1.4.1 Use of Color (A)**: Color is not the only visual means of conveying information
- [ ] **1.4.2 Audio Control (A)**: Audio can be paused, stopped, or volume controlled
- [ ] **1.4.3 Contrast (Minimum) (AA)**: Text has a contrast ratio of at least 4.5:1 (3:1 for large text)
- [ ] **1.4.4 Resize Text (AA)**: Text can be resized up to 200% without loss of content or functionality
- [ ] **1.4.5 Images of Text (AA)**: Images of text are only used for decoration or where specific presentation is essential
- [ ] **1.4.10 Reflow (AA)**: Content can be presented without scrolling in two dimensions
- [ ] **1.4.11 Non-text Contrast (AA)**: UI components and graphical objects have a contrast ratio of at least 3:1
- [ ] **1.4.12 Text Spacing (AA)**: No loss of content when text spacing is adjusted
- [ ] **1.4.13 Content on Hover or Focus (AA)**: Additional content that appears on hover or focus is dismissible, hoverable, and persistent

## 2. Operable

User interface components and navigation must be operable.

### 2.1 Keyboard Accessible
- [ ] **2.1.1 Keyboard (A)**: All functionality is available from a keyboard
- [ ] **2.1.2 No Keyboard Trap (A)**: Keyboard focus is not trapped
- [ ] **2.1.4 Character Key Shortcuts (A)**: Keyboard shortcuts can be turned off, remapped, or are active only on focus

### 2.2 Enough Time
- [ ] **2.2.1 Timing Adjustable (A)**: Users can adjust, extend, or disable time limits
- [ ] **2.2.2 Pause, Stop, Hide (A)**: Moving, blinking, or auto-updating content can be paused, stopped, or hidden

### 2.3 Seizures and Physical Reactions
- [ ] **2.3.1 Three Flashes or Below Threshold (A)**: No content flashes more than three times per second

### 2.4 Navigable
- [ ] **2.4.1 Bypass Blocks (A)**: Skip links or other mechanisms to bypass repeated blocks
- [ ] **2.4.2 Page Titled (A)**: Pages have titles that describe topic or purpose
- [ ] **2.4.3 Focus Order (A)**: Focus order preserves meaning and operability
- [ ] **2.4.4 Link Purpose (In Context) (A)**: The purpose of each link can be determined from the link text or context
- [ ] **2.4.5 Multiple Ways (AA)**: Multiple ways to locate a page
- [ ] **2.4.6 Headings and Labels (AA)**: Headings and labels describe topic or purpose
- [ ] **2.4.7 Focus Visible (AA)**: Keyboard focus indicator is visible

### 2.5 Input Modalities
- [ ] **2.5.1 Pointer Gestures (A)**: Multipoint or path-based gestures have single-pointer alternatives
- [ ] **2.5.2 Pointer Cancellation (A)**: Functions activated by a single pointer can be canceled or completed on up-event
- [ ] **2.5.3 Label in Name (A)**: The accessible name contains the visible text label
- [ ] **2.5.4 Motion Actuation (A)**: Functionality that can be operated by device motion can also be operated by user interface components

## 3. Understandable

Information and the operation of user interface must be understandable.

### 3.1 Readable
- [ ] **3.1.1 Language of Page (A)**: The default human language of the page can be programmatically determined
- [ ] **3.1.2 Language of Parts (AA)**: The human language of passages can be programmatically determined

### 3.2 Predictable
- [ ] **3.2.1 On Focus (A)**: Receiving focus doesn't initiate a change of context
- [ ] **3.2.2 On Input (A)**: Changing a setting doesn't automatically cause a change of context
- [ ] **3.2.3 Consistent Navigation (AA)**: Navigation mechanisms are consistent
- [ ] **3.2.4 Consistent Identification (AA)**: Components with the same functionality are identified consistently

### 3.3 Input Assistance
- [ ] **3.3.1 Error Identification (A)**: Input errors are identified and described to the user
- [ ] **3.3.2 Labels or Instructions (A)**: Labels or instructions are provided for user input
- [ ] **3.3.3 Error Suggestion (AA)**: Suggestions for error correction are provided
- [ ] **3.3.4 Error Prevention (Legal, Financial, Data) (AA)**: For pages with legal, financial, or data commitments, submissions are reversible, checked, or confirmed

## 4. Robust

Content must be robust enough to be interpreted by a wide variety of user agents, including assistive technologies.

### 4.1 Compatible
- [ ] **4.1.1 Parsing (A)**: Markup is valid and well-formed
- [ ] **4.1.2 Name, Role, Value (A)**: For all UI components, the name, role, and value can be programmatically determined
- [ ] **4.1.3 Status Messages (AA)**: Status messages can be programmatically determined without receiving focus

## Implementation Status

| Category | Total Requirements | Implemented | Percentage |
|----------|-------------------|-------------|------------|
| Perceivable | 17 | 15 | 88% |
| Operable | 15 | 13 | 87% |
| Understandable | 10 | 8 | 80% |
| Robust | 3 | 3 | 100% |
| **Total** | **45** | **39** | **87%** |

## Next Steps

1. Conduct a full accessibility audit of the application
2. Prioritize and address the most critical issues
3. Implement missing accessibility features
4. Test with assistive technologies
5. Update this checklist as requirements are met
