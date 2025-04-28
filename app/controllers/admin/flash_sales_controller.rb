module Admin
  class FlashSalesController < AdminController
    before_action :set_flash_sale, only: [:show, :edit, :update, :destroy, :toggle_active, :add_product, :remove_product]
    
    def index
      @flash_sales = FlashSale.all.order(starts_at: :desc)
      
      if params[:status].present?
        case params[:status]
        when 'active'
          @flash_sales = @flash_sales.active
        when 'inactive'
          @flash_sales = @flash_sales.where(active: false)
        when 'current'
          @flash_sales = @flash_sales.current
        when 'upcoming'
          @flash_sales = @flash_sales.upcoming
        when 'past'
          @flash_sales = @flash_sales.past
        end
      end
      
      if params[:featured].present?
        @flash_sales = @flash_sales.where(featured: params[:featured] == 'true')
      end
      
      @pagy, @flash_sales = pagy(@flash_sales, items: 20)
    end
    
    def show
      @flash_sale_items = @flash_sale.flash_sale_items.includes(:product).order('products.name')
    end
    
    def new
      @flash_sale = FlashSale.new
    end
    
    def create
      @flash_sale = FlashSale.new(flash_sale_params)
      
      if @flash_sale.save
        redirect_to admin_flash_sale_path(@flash_sale), notice: 'Flash sale was successfully created.'
      else
        render :new
      end
    end
    
    def edit
    end
    
    def update
      if @flash_sale.update(flash_sale_params)
        redirect_to admin_flash_sale_path(@flash_sale), notice: 'Flash sale was successfully updated.'
      else
        render :edit
      end
    end
    
    def destroy
      @flash_sale.destroy
      redirect_to admin_flash_sales_path, notice: 'Flash sale was successfully deleted.'
    end
    
    def toggle_active
      @flash_sale.update(active: !@flash_sale.active)
      redirect_to admin_flash_sale_path(@flash_sale), notice: "Flash sale was #{@flash_sale.active? ? 'activated' : 'deactivated'}."
    end
    
    def add_product
      @products = Product.active.where.not(id: @flash_sale.product_ids).order(:name)
      
      if request.post?
        product_ids = params[:product_ids] || []
        discount_value = params[:discount_value]
        discount_type = params[:discount_type]
        quantity_limit = params[:quantity_limit].presence
        
        if product_ids.empty?
          flash.now[:alert] = 'Please select at least one product.'
          render :add_product
          return
        end
        
        if discount_value.blank? || discount_value.to_f <= 0
          flash.now[:alert] = 'Please enter a valid discount value.'
          render :add_product
          return
        end
        
        added_count = 0
        
        product_ids.each do |product_id|
          product = Product.find(product_id)
          flash_sale_item = @flash_sale.flash_sale_items.build(
            product: product,
            discount_value: discount_value,
            discount_type: discount_type,
            quantity_limit: quantity_limit
          )
          
          added_count += 1 if flash_sale_item.save
        end
        
        redirect_to admin_flash_sale_path(@flash_sale), notice: "Added #{added_count} products to the flash sale."
      end
    end
    
    def remove_product
      flash_sale_item = @flash_sale.flash_sale_items.find_by(product_id: params[:product_id])
      
      if flash_sale_item&.destroy
        redirect_to admin_flash_sale_path(@flash_sale), notice: 'Product was removed from the flash sale.'
      else
        redirect_to admin_flash_sale_path(@flash_sale), alert: 'Failed to remove product from the flash sale.'
      end
    end
    
    private
    
    def set_flash_sale
      @flash_sale = FlashSale.find(params[:id])
    end
    
    def flash_sale_params
      params.require(:flash_sale).permit(
        :name, :description, :starts_at, :ends_at, :active, :featured,
        :banner_text, :banner_color, :banner_text_color
      )
    end
  end
end
