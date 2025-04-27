class Admin::ShopCategoriesController < Admin::BaseController
  before_action :set_shop_category, only: [:show, :edit, :update, :destroy, :feature, :unfeature]
  
  def index
    @pagy, @shop_categories = pagy(ShopCategory.all.order(:name), items: 20)
  end
  
  def show
    @products = @shop_category.products.order(created_at: :desc).limit(10)
  end
  
  def new
    @shop_category = ShopCategory.new
    @parent_categories = ShopCategory.root_categories
  end
  
  def create
    @shop_category = ShopCategory.new(shop_category_params)
    
    if @shop_category.save
      redirect_to admin_shop_category_path(@shop_category), notice: "Category was successfully created."
    else
      @parent_categories = ShopCategory.root_categories
      render :new
    end
  end
  
  def edit
    @parent_categories = ShopCategory.where.not(id: @shop_category.id).root_categories
  end
  
  def update
    if @shop_category.update(shop_category_params)
      redirect_to admin_shop_category_path(@shop_category), notice: "Category was successfully updated."
    else
      @parent_categories = ShopCategory.where.not(id: @shop_category.id).root_categories
      render :edit
    end
  end
  
  def destroy
    if @shop_category.products.exists?
      redirect_to admin_shop_categories_path, alert: "Cannot delete category with associated products."
    else
      @shop_category.destroy
      redirect_to admin_shop_categories_path, notice: "Category was successfully deleted."
    end
  end
  
  def feature
    @shop_category.update(featured: true)
    redirect_to admin_shop_category_path(@shop_category), notice: "Category is now featured."
  end
  
  def unfeature
    @shop_category.update(featured: false)
    redirect_to admin_shop_category_path(@shop_category), notice: "Category is no longer featured."
  end
  
  private
  
  def set_shop_category
    @shop_category = ShopCategory.find(params[:id])
  end
  
  def shop_category_params
    params.require(:shop_category).permit(:name, :description, :slug, :icon, :color_code, :parent_id, :featured, :active, :position)
  end
end
