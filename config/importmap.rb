# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
# Theme and appearance system
pin "theme_initializer", preload: true
pin "appearance_initializer", preload: true
pin_all_from "app/javascript/theme", under: "theme"

# Custom components
pin "tabs"
pin "lightbox"
pin "test_tabs" # Temporary for debugging
pin "components/tabs"
pin "simple_tabs" # New simplified tabs implementation
pin "admin_tabs" # Admin-specific tabs implementation

# Third-party libraries
pin "sortablejs", to: "https://ga.jspm.io/npm:sortablejs@1.15.0/modular/sortable.esm.js"
