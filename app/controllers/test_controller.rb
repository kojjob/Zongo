class TestController < ApplicationController
  # Skip authentication for testing
  # skip_before_action :authenticate_user!, if: -> { defined?(authenticate_user!) }
  
  def index
    # Simple test page
  end
  
  def theme_test
    # Standalone theme test page (no layout)
    render layout: false
  end
  
  def dropdown_test
    # Standalone dropdown test page (no layout)
    render layout: false
  end
  
  def main_app_test
    # Test page that uses the application layout
  end
end
