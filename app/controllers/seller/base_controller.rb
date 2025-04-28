module Seller
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_seller
    layout "seller"
    
    private
    
    def require_seller
      # For now, any authenticated user can be a seller
      # In the future, you might want to add a seller role or verification process
      true
    end
  end
end
