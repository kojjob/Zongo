# WickedPDF Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `render :pdf` call.
#
# To learn more, check out the README:
#
# https://github.com/mileszs/wicked_pdf/blob/master/README.md

WickedPdf.config ||= {
  # Path to the wkhtmltopdf executable: This usually isn't needed if using
  # the wkhtmltopdf-binary gem
  # exe_path: '/usr/local/bin/wkhtmltopdf',

  # Layout file to be used for all PDFs
  # (but can be overridden in `render :pdf` calls)
  layout: "pdf.html.erb",

  # Using wkhtmltopdf without an X server can be achieved by enabling 'use_xvfb: true'.
  # This will use the 'xvfb-run' command to execute the wkhtmltopdf binary.
  # use_xvfb: true,

  # PDF generation defaults
  margin: {
    top: 20,
    bottom: 20,
    left: 20,
    right: 20
  },

  # Header and footer configuration
  header: {
    html: {
      template: "shared/pdf_header"
    },
    spacing: 10
  },

  footer: {
    right: "[page] of [topage]",
    font_size: 8,
    spacing: 10
  },

  # PDF page size
  page_size: "A4",

  # PDF orientation
  orientation: "Portrait",

  # Encoding
  encoding: "UTF-8"

  # Additional command-line options to wkhtmltopdf
  # quiet: false,

  # Image quality
  # dpi: 96
}
