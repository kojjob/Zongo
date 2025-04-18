module Admin
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_product, only: [ :show, :edit, :update, :destroy, :suspend, :activate ]
    layout "admin"

    def index
      @products = Product.all.order(created_at: :desc)

      # Filter by status if provided
      if params[:status].present?
        @products = @products.where(status: params[:status])
      end

      # Filter by category if provided
      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      # Filter by search term if provided
      if params[:search].present?
        @products = @products.where("name LIKE ? OR description LIKE ?",
                                  "%#{params[:search]}%",
                                  "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @products = pagy(@products, items: 10)
    end

    def show
    end

    def new
      @product = Product.new
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_product_path(@product), notice: "Product was successfully created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "Product was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "Product was successfully deleted."
    end

    def suspend
      if @product.update(status: :suspended)
        redirect_to admin_product_path(@product), notice: "Product has been suspended."
      else
        redirect_to admin_product_path(@product), alert: "Failed to suspend product."
      end
    end

    def activate
      if @product.update(status: :active)
        redirect_to admin_product_path(@product), notice: "Product has been activated."
      else
        redirect_to admin_product_path(@product), alert: "Failed to activate product."
      end
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :price, :category_id, :status, :featured)
    end
  end
end
