class MarketplaceController < ApplicationController
  def index
    # Main marketplace page
    @page_title = "Marketplace"
  end

  def electronics
    # Electronics category page
    @page_title = "Electronics"
    @category = "electronics"
    @subcategory = params[:subcategory]
    render :category
  end

  def fashion
    # Fashion category page
    @page_title = "Fashion"
    @category = "fashion"
    @subcategory = params[:subcategory]
    render :category
  end

  def groceries
    # Groceries category page
    @page_title = "Groceries"
    @category = "groceries"
    @subcategory = params[:subcategory]
    render :category
  end

  def local
    # Local marketplace page
    @page_title = "Local Marketplace"
    @category = "local"
    @subcategory = params[:subcategory]
    render :category
  end

  def subcategory
    # Handle subcategory pages
    @category = params[:category]
    @subcategory = params[:subcategory]

    case @category
    when 'electronics'
      @page_title = @subcategory.titleize
      render :category
    when 'fashion'
      @page_title = @subcategory.titleize
      render :category
    when 'groceries'
      @page_title = @subcategory.titleize
      render :category
    when 'local'
      @page_title = @subcategory.titleize
      render :category
    else
      redirect_to marketplace_path, alert: "Category not found"
    end
  end
end
