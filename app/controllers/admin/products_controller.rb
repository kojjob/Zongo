module Admin
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_product, only: [ :show, :edit, :update, :destroy, :feature, :unfeature, :approve, :reject ]
    layout "admin"

    def index
      products_query = Product.all

      # Apply filters
      if params[:category_id].present?
        products_query = products_query.where(shop_category_id: params[:category_id])
      end

      if params[:status].present?
        products_query = products_query.where(status: params[:status])
      end

      if params[:featured].present?
        products_query = products_query.where(featured: params[:featured] == "true")
      end

      if params[:min_price].present? && params[:max_price].present?
        products_query = products_query.where(price: params[:min_price]..params[:max_price])
      end

      if params[:search].present?
        products_query = products_query.where("name ILIKE ? OR description ILIKE ? OR sku ILIKE ?",
                                            "%#{params[:search]}%",
                                            "%#{params[:search]}%",
                                            "%#{params[:search]}%")
      end

      # Apply sorting
      case params[:sort]
      when "price_asc"
        products_query = products_query.order(price: :asc)
      when "price_desc"
        products_query = products_query.order(price: :desc)
      when "name_asc"
        products_query = products_query.order(name: :asc)
      when "name_desc"
        products_query = products_query.order(name: :desc)
      when "newest"
        products_query = products_query.order(created_at: :desc)
      when "oldest"
        products_query = products_query.order(created_at: :asc)
      else
        products_query = products_query.order(created_at: :desc)
      end

      @pagy, @products = pagy(products_query, items: 20)
      @categories = ShopCategory.all.order(:name)
    end

    def show
      @reviews = @product.reviews.order(created_at: :desc).limit(5)
      @orders = Order.joins(:order_items).where(order_items: { product_id: @product.id }).distinct.order(created_at: :desc).limit(5)
    end

    def new
      @product = Product.new
      @categories = ShopCategory.all.order(:name)
      @sellers = User.all.order(:username)
    end

    def create
      @product = Product.new(product_params)

      # Set a default shop category if none is selected
      if @product.shop_category_id.blank?
        default_category = ShopCategory.first
        if default_category
          @product.shop_category_id = default_category.id
        else
          # Create a default category if none exists
          default_category = ShopCategory.create(name: "General", description: "Default category")
          @product.shop_category_id = default_category.id
        end
      end

      # Set the current user as the seller if none is selected
      if @product.user_id.blank?
        @product.user_id = current_user.id
      end

      if @product.save
        redirect_to admin_product_path(@product), notice: "Product was successfully created."
      else
        @categories = ShopCategory.all.order(:name)
        @sellers = User.all.order(:username)
        render :new
      end
    end

    def edit
      @categories = ShopCategory.all.order(:name)
      @sellers = User.all.order(:username)
    end

    def update
      product_attributes = product_params

      # Set a default shop category if none is selected
      if product_attributes[:shop_category_id].blank?
        default_category = ShopCategory.first
        if default_category
          product_attributes[:shop_category_id] = default_category.id
        else
          # Create a default category if none exists
          default_category = ShopCategory.create(name: "General", description: "Default category")
          product_attributes[:shop_category_id] = default_category.id
        end
      end

      # Set the current user as the seller if none is selected
      if product_attributes[:user_id].blank?
        product_attributes[:user_id] = current_user.id
      end

      if @product.update(product_attributes)
        redirect_to admin_product_path(@product), notice: "Product was successfully updated."
      else
        @categories = ShopCategory.all.order(:name)
        @sellers = User.all.order(:username)
        render :edit
      end
    end

    def destroy
      if @product.order_items.exists?
        redirect_to admin_products_path, alert: "Cannot delete product with associated orders."
      else
        @product.destroy
        redirect_to admin_products_path, notice: "Product was successfully deleted."
      end
    end

    def feature
      @product.update(featured: true)
      redirect_to admin_product_path(@product), notice: "Product is now featured."
    end

    def unfeature
      @product.update(featured: false)
      redirect_to admin_product_path(@product), notice: "Product is no longer featured."
    end

    def approve
      @product.update(status: :active)
      redirect_to admin_product_path(@product), notice: "Product has been approved and is now active."
    end

    def reject
      @product.update(status: :inactive)
      redirect_to admin_product_path(@product), notice: "Product has been rejected and is now inactive."
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name, :description, :price, :original_price, :stock_quantity, :sku,
        :shop_category_id, :user_id, :status, :featured, :brand, :product_type,
        :weight, :weight_unit, :length, :width, :height, :dimension_unit,
        :digital_file, specifications: {}, tags: [], images: []
      )
    end
  end
end
