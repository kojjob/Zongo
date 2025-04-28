module Admin
  class CouponsController < AdminController
    before_action :set_coupon, only: [:show, :edit, :update, :destroy, :toggle_active]
    
    def index
      @coupons = Coupon.all.order(created_at: :desc)
      
      if params[:status].present?
        case params[:status]
        when 'active'
          @coupons = @coupons.active
        when 'inactive'
          @coupons = @coupons.where(active: false)
        when 'current'
          @coupons = @coupons.current
        when 'expired'
          @coupons = @coupons.where('ends_at < ?', Time.current)
        end
      end
      
      if params[:category_id].present?
        @coupons = @coupons.by_category(params[:category_id])
      end
      
      if params[:discount_type].present?
        @coupons = @coupons.where(discount_type: params[:discount_type])
      end
      
      if params[:search].present?
        @coupons = @coupons.where('code ILIKE ? OR name ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
      end
      
      @pagy, @coupons = pagy(@coupons, items: 20)
    end
    
    def show
      @orders = @coupon.orders.order(created_at: :desc).limit(10)
    end
    
    def new
      @coupon = Coupon.new
      @categories = ShopCategory.all.order(:name)
    end
    
    def create
      @coupon = Coupon.new(coupon_params)
      
      if @coupon.save
        redirect_to admin_coupon_path(@coupon), notice: 'Coupon was successfully created.'
      else
        @categories = ShopCategory.all.order(:name)
        render :new
      end
    end
    
    def edit
      @categories = ShopCategory.all.order(:name)
    end
    
    def update
      if @coupon.update(coupon_params)
        redirect_to admin_coupon_path(@coupon), notice: 'Coupon was successfully updated.'
      else
        @categories = ShopCategory.all.order(:name)
        render :edit
      end
    end
    
    def destroy
      if @coupon.orders.exists?
        redirect_to admin_coupon_path(@coupon), alert: 'Cannot delete coupon with associated orders.'
      else
        @coupon.destroy
        redirect_to admin_coupons_path, notice: 'Coupon was successfully deleted.'
      end
    end
    
    def toggle_active
      @coupon.update(active: !@coupon.active)
      redirect_to admin_coupon_path(@coupon), notice: "Coupon was #{@coupon.active? ? 'activated' : 'deactivated'}."
    end
    
    def generate_code
      code = SecureRandom.alphanumeric(8).upcase
      
      # Ensure the code is unique
      while Coupon.exists?(code: code)
        code = SecureRandom.alphanumeric(8).upcase
      end
      
      render json: { code: code }
    end
    
    private
    
    def set_coupon
      @coupon = Coupon.find(params[:id])
    end
    
    def coupon_params
      params.require(:coupon).permit(
        :code, :name, :description, :value, :discount_type, :starts_at, :ends_at,
        :active, :usage_limit, :minimum_order_amount, :shop_category_id, :first_time_purchase_only
      )
    end
  end
end
