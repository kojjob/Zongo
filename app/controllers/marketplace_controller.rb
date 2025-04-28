class MarketplaceController < ApplicationController
  def index
    # Main marketplace page
    @page_title = "Marketplace"
  end

  def electronics
    # Electronics category page
    @page_title = "Electronics"
    @category = "electronics"
    render :category
  end

  def fashion
    # Fashion category page
    @page_title = "Fashion"
    @category = "fashion"
    render :category
  end

  def groceries
    # Groceries category page
    @page_title = "Groceries"
    @category = "groceries"
    render :category
  end

  def local
    # Local marketplace page
    @page_title = "Local Marketplace"
    @category = "local"
    render :category
  end
end
