class DigitalDownloadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order_item
  
  def download
    # Check if the product is digital
    unless @order_item.product.digital?
      redirect_to order_path(@order_item.order), alert: "This product is not a digital product."
      return
    end
    
    # Check if the order is paid
    unless @order_item.order.paid?
      redirect_to order_path(@order_item.order), alert: "You need to complete payment for this order before downloading."
      return
    end
    
    # Check if the digital file is attached
    unless @order_item.product.digital_file.attached?
      redirect_to order_path(@order_item.order), alert: "The digital file is not available for download."
      return
    end
    
    # Track the download
    @download = DigitalDownload.create(
      user: current_user,
      order_item: @order_item,
      product: @order_item.product,
      ip_address: request.remote_ip
    )
    
    # Check download limits if applicable
    if @order_item.product.download_limit.present? && @order_item.product.download_limit > 0
      download_count = DigitalDownload.where(user: current_user, product: @order_item.product).count
      
      if download_count > @order_item.product.download_limit
        redirect_to order_path(@order_item.order), alert: "You have reached the maximum number of downloads for this product."
        return
      end
    end
    
    # Serve the file
    redirect_to url_for(@order_item.product.digital_file)
  end
  
  private
  
  def set_order_item
    @order_item = OrderItem.find(params[:id])
    
    # Ensure the user owns this order
    unless @order_item.order.user == current_user
      redirect_to orders_path, alert: "You don't have permission to access this download."
      return
    end
  end
end
