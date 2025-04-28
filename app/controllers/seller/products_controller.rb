module Seller
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy]
    
    def index
      products_query = current_user.products
      
      # Apply filters
      if params[:category_id].present?
        products_query = products_query.where(shop_category_id: params[:category_id])
      end
      
      if params[:status].present?
        products_query = products_query.where(status: params[:status])
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
      @orders = Order.joins(:order_items)
                    .where(order_items: { product_id: @product.id })
                    .distinct
                    .order(created_at: :desc)
                    .limit(5)
    end
    
    def new
      @product = current_user.products.new
      @categories = ShopCategory.all.order(:name)
    end
    
    def create
      @product = current_user.products.new(product_params)
      
      if @product.save
        redirect_to seller_product_path(@product), notice: "Product was successfully created."
      else
        @categories = ShopCategory.all.order(:name)
        render :new
      end
    end
    
    def edit
      @categories = ShopCategory.all.order(:name)
    end
    
    def update
      if @product.update(product_params)
        redirect_to seller_product_path(@product), notice: "Product was successfully updated."
      else
        @categories = ShopCategory.all.order(:name)
        render :edit
      end
    end
    
    def destroy
      if @product.order_items.exists?
        redirect_to seller_products_path, alert: "Cannot delete product with associated orders."
      else
        @product.destroy
        redirect_to seller_products_path, notice: "Product was successfully deleted."
      end
    end
    
    def bulk_new
      @categories = ShopCategory.all.order(:name)
    end
    
    def bulk_create
      if params[:csv_file].present?
        begin
          csv_data = CSV.parse(params[:csv_file].read, headers: true)
          
          # Track success and failures
          @success_count = 0
          @failure_count = 0
          @errors = []
          
          # Process each row
          csv_data.each do |row|
            product = current_user.products.new(
              name: row['name'],
              description: row['description'],
              price: row['price'],
              original_price: row['original_price'],
              stock_quantity: row['stock_quantity'],
              sku: row['sku'],
              shop_category_id: row['shop_category_id'],
              status: row['status'] || 'active',
              brand: row['brand'],
              weight: row['weight'],
              weight_unit: row['weight_unit'],
              length: row['length'],
              width: row['width'],
              height: row['height'],
              dimension_unit: row['dimension_unit']
            )
            
            if product.save
              @success_count += 1
            else
              @failure_count += 1
              @errors << "Row #{csv_data.find_index(row) + 2}: #{product.errors.full_messages.join(', ')}"
            end
          end
          
          if @failure_count.zero?
            redirect_to seller_products_path, notice: "Successfully imported #{@success_count} products."
          else
            flash.now[:alert] = "Imported #{@success_count} products with #{@failure_count} failures."
            @categories = ShopCategory.all.order(:name)
            render :bulk_new
          end
        rescue => e
          flash.now[:alert] = "Error processing CSV file: #{e.message}"
          @categories = ShopCategory.all.order(:name)
          render :bulk_new
        end
      else
        flash.now[:alert] = "Please select a CSV file to upload."
        @categories = ShopCategory.all.order(:name)
        render :bulk_new
      end
    end
    
    def bulk_edit
      @products = current_user.products.where(id: params[:product_ids])
      @categories = ShopCategory.all.order(:name)
      
      if @products.empty?
        redirect_to seller_products_path, alert: "No products selected for bulk editing."
      end
    end
    
    def bulk_update
      @products = current_user.products.where(id: params[:product_ids])
      
      if @products.empty?
        redirect_to seller_products_path, alert: "No products selected for bulk updating."
        return
      end
      
      # Track success and failures
      success_count = 0
      failure_count = 0
      
      # Only update fields that are provided
      update_params = {}
      update_params[:shop_category_id] = params[:shop_category_id] if params[:shop_category_id].present?
      update_params[:status] = params[:status] if params[:status].present?
      update_params[:price] = params[:price] if params[:price].present?
      update_params[:stock_quantity] = params[:stock_quantity] if params[:stock_quantity].present?
      
      # Apply percentage price change if specified
      if params[:price_change_type] == 'percentage' && params[:price_change_value].present?
        percentage = params[:price_change_value].to_f / 100
        
        @products.each do |product|
          new_price = product.price * (1 + percentage)
          if product.update(price: new_price.round(2))
            success_count += 1
          else
            failure_count += 1
          end
        end
      else
        # Apply direct updates
        if update_params.present?
          @products.each do |product|
            if product.update(update_params)
              success_count += 1
            else
              failure_count += 1
            end
          end
        else
          redirect_to seller_products_path, alert: "No update parameters provided."
          return
        end
      end
      
      if failure_count.zero?
        redirect_to seller_products_path, notice: "Successfully updated #{success_count} products."
      else
        redirect_to seller_products_path, alert: "Updated #{success_count} products with #{failure_count} failures."
      end
    end
    
    def download_csv_template
      csv_data = CSV.generate do |csv|
        # Header row
        csv << ['name', 'description', 'price', 'original_price', 'stock_quantity', 'sku', 'shop_category_id', 'status', 'brand', 'weight', 'weight_unit', 'length', 'width', 'height', 'dimension_unit']
        
        # Example row
        csv << ['Example Product', 'This is a sample product description', '99.99', '129.99', '100', '', '1', 'active', 'Brand Name', '1.5', 'kg', '10', '5', '2', 'cm']
      end
      
      send_data csv_data, filename: "product_import_template.csv", type: "text/csv"
    end
    
    private
    
    def set_product
      @product = current_user.products.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to seller_products_path, alert: "Product not found or you don't have permission to access it."
    end
    
    def product_params
      params.require(:product).permit(
        :name, :description, :price, :original_price, :stock_quantity, :sku,
        :shop_category_id, :status, :featured, :brand,
        :weight, :weight_unit, :length, :width, :height, :dimension_unit,
        specifications: {}, tags: [], images: []
      )
    end
  end
end
