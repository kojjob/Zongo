class HeroBannersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :check_setting_model
  
  # PATCH /hero_banners
  def update
    if params[:hero_banner].present?
      # Create or update the hero banner setting
      @setting = Setting.find_or_initialize_by(key: 'events_hero_banner')
      
      # Store the banner using Active Storage
      @setting.image.attach(params[:hero_banner])
      
      if @setting.save
        redirect_to events_path, notice: "Hero banner was successfully updated."
      else
        redirect_to events_path, alert: "Error updating hero banner: #{@setting.errors.full_messages.join(', ')}"
      end
    else
      redirect_to events_path, alert: "Please select an image."
    end
  rescue => e
    redirect_to events_path, alert: "Error uploading hero banner: #{e.message}"
  end
  
  # DELETE /hero_banners
  def destroy
    @setting = Setting.find_by(key: 'events_hero_banner')
    
    if @setting&.image&.attached?
      @setting.image.purge
      redirect_to events_path, notice: "Hero banner was successfully removed."
    else
      redirect_to events_path, alert: "No hero banner found."
    end
  rescue => e
    redirect_to events_path, alert: "Error removing hero banner: #{e.message}"
  end
  
  private
  
  def require_admin
    # Customize this method to match your application's admin role checking system
    is_admin = current_user.try(:admin?) || 
              current_user.try(:is_admin) || 
              current_user.try(:role) == 'admin' || 
              current_user.try(:admin) == true ||
              ENV['SHOW_ADMIN_TO_ALL'] == 'true' # Development mode - remove in production!
              
    unless is_admin
      redirect_to events_path, alert: "You don't have permission to perform this action."
    end
  end
  
  def check_setting_model
    unless defined?(Setting)
      redirect_to events_path, alert: "Setting model not found. Please run migration to create the settings table."
    end
  end
end
