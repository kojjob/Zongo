module Admin
  class DiscountsController < AdminController
    before_action :set_discount, only: [:show, :edit, :update, :destroy, :toggle_active]
    
    def index
      @discounts = Discount.all.order(created_at: :desc)
      
      if params[:status].present?
        case params[:status]
        when 'active'
          @discounts = @discounts.active
        when 'inactive'
          @discounts = @discounts.where(active: false)
        when 'current'
          @discounts = @discounts.current
        when 'expired'
          @discounts = @discounts.where('ends_at < ?', Time.current)
        end
      end
      
      if params[:category_id].present?
        @discounts = @discounts.by_category(params[:category_id])
      end
      
      if params[:product_id].present?
        @discounts = @discounts.by_product(params[:product_id])
      end
      
      if params[:discount_type].present?
        @discounts = @discounts.where(discount_type: params[:discount_type])
      end
      
      if params[:featured].present?
        @discounts = @discounts.where(featured: params[:featured] == 'true')
      end
      
      @pagy, @discounts = pagy(@discounts, items: 20)
    end
    
    def show
    end
    
    def new
      @discount = Discount.new
      @categories = ShopCategory.all.order(:name)
      @products = Product.active.order(:name)
    end
    
    def create
      @discount = Discount.new(discount_params)
      
      if @discount.save
        redirect_to admin_discount_path(@discount), notice: 'Discount was successfully created.'
      else
        @categories = ShopCategory.all.order(:name)
        @products = Product.active.order(:name)
        render :new
      end
    end
    
    def edit
      @categories = ShopCategory.all.order(:name)
      @products = Product.active.order(:name)
    end
    
    def update
      if @discount.update(discount_params)
        redirect_to admin_discount_path(@discount), notice: 'Discount was successfully updated.'
      else
        @categories = ShopCategory.all.order(:name)
        @products = Product.active.order(:name)
        render :edit
      end
    end
    
    def destroy
      @discount.destroy
      redirect_to admin_discounts_path, notice: 'Discount was successfully deleted.'
    end
    
    def toggle_active
      @discount.update(active: !@discount.active)
      redirect_to admin_discount_path(@discount), notice: "Discount was #{@discount.active? ? 'activated' : 'deactivated'}."
    end
    
    private
    
    def set_discount
      @discount = Discount.find(params[:id])
    end
    
    def discount_params
      params.require(:discount).permit(
        :name, :description, :value, :discount_type, :starts_at, :ends_at,
        :active, :usage_limit, :shop_category_id, :product_id, :featured
      )
    end
  end
end
