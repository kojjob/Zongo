module Admin
  class PromotionalBannersController < AdminController
    before_action :set_promotional_banner, only: [:show, :edit, :update, :destroy, :toggle_active]
    
    def index
      @promotional_banners = PromotionalBanner.all.ordered
      
      if params[:status].present?
        case params[:status]
        when 'active'
          @promotional_banners = @promotional_banners.active
        when 'inactive'
          @promotional_banners = @promotional_banners.where(active: false)
        when 'current'
          @promotional_banners = @promotional_banners.current
        when 'expired'
          @promotional_banners = @promotional_banners.where('ends_at < ?', Time.current)
        end
      end
      
      if params[:location].present?
        @promotional_banners = @promotional_banners.by_location(params[:location])
      end
      
      if params[:category_id].present?
        @promotional_banners = @promotional_banners.by_category(params[:category_id])
      end
      
      @pagy, @promotional_banners = pagy(@promotional_banners, items: 20)
    end
    
    def show
    end
    
    def new
      @promotional_banner = PromotionalBanner.new
      @categories = ShopCategory.all.order(:name)
      @locations = location_options
    end
    
    def create
      @promotional_banner = PromotionalBanner.new(promotional_banner_params)
      
      if @promotional_banner.save
        redirect_to admin_promotional_banner_path(@promotional_banner), notice: 'Promotional banner was successfully created.'
      else
        @categories = ShopCategory.all.order(:name)
        @locations = location_options
        render :new
      end
    end
    
    def edit
      @categories = ShopCategory.all.order(:name)
      @locations = location_options
    end
    
    def update
      if @promotional_banner.update(promotional_banner_params)
        redirect_to admin_promotional_banner_path(@promotional_banner), notice: 'Promotional banner was successfully updated.'
      else
        @categories = ShopCategory.all.order(:name)
        @locations = location_options
        render :edit
      end
    end
    
    def destroy
      @promotional_banner.destroy
      redirect_to admin_promotional_banners_path, notice: 'Promotional banner was successfully deleted.'
    end
    
    def toggle_active
      @promotional_banner.update(active: !@promotional_banner.active)
      redirect_to admin_promotional_banner_path(@promotional_banner), notice: "Promotional banner was #{@promotional_banner.active? ? 'activated' : 'deactivated'}."
    end
    
    def reorder
      params[:banner_ids].each_with_index do |id, index|
        PromotionalBanner.where(id: id).update_all(position: index)
      end
      
      head :ok
    end
    
    private
    
    def set_promotional_banner
      @promotional_banner = PromotionalBanner.find(params[:id])
    end
    
    def promotional_banner_params
      params.require(:promotional_banner).permit(
        :title, :description, :button_text, :link_url, :starts_at, :ends_at,
        :active, :position, :background_color, :text_color, :button_color,
        :button_text_color, :location, :shop_category_id, :image
      )
    end
    
    def location_options
      [
        ['Home Page', 'home'],
        ['Marketplace', 'marketplace'],
        ['Category Pages', 'category'],
        ['Product Pages', 'product'],
        ['Cart Page', 'cart'],
        ['Checkout Page', 'checkout'],
        ['User Dashboard', 'dashboard']
      ]
    end
  end
end
