class NotificationPreferencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification_preference
  
  # GET /notification_preferences
  def show
    @page_title = "Notification Preferences"
    @notification_channels = current_user.notification_channels.order(:channel_type, :created_at)
  end
  
  # PATCH /notification_preferences
  def update
    if @notification_preference.update(notification_preference_params)
      flash[:notice] = "Notification preferences updated successfully."
      redirect_to notification_preferences_path
    else
      flash.now[:alert] = "Failed to update notification preferences."
      @notification_channels = current_user.notification_channels.order(:channel_type, :created_at)
      render :show
    end
  end
  
  # POST /notification_preferences/add_channel
  def add_channel
    @channel = current_user.notification_channels.new(channel_params)
    
    if @channel.save
      # Send verification if needed
      @channel.send_verification if @channel.channel_type.in?(['email', 'sms'])
      
      flash[:notice] = "Notification channel added successfully. Please verify it to receive notifications."
      redirect_to notification_preferences_path
    else
      flash.now[:alert] = "Failed to add notification channel: #{@channel.errors.full_messages.join(', ')}"
      @notification_preference = current_user.notification_preference
      @notification_channels = current_user.notification_channels.order(:channel_type, :created_at)
      render :show
    end
  end
  
  # DELETE /notification_preferences/remove_channel/:id
  def remove_channel
    @channel = current_user.notification_channels.find(params[:id])
    
    if @channel.destroy
      flash[:notice] = "Notification channel removed successfully."
    else
      flash[:alert] = "Failed to remove notification channel."
    end
    
    redirect_to notification_preferences_path
  end
  
  # POST /notification_preferences/verify_channel/:id
  def verify_channel
    @channel = current_user.notification_channels.find(params[:id])
    
    if @channel.verify_with_token(params[:token])
      flash[:notice] = "Notification channel verified successfully."
    else
      flash[:alert] = "Failed to verify notification channel. Please check the verification code and try again."
    end
    
    redirect_to notification_preferences_path
  end
  
  # POST /notification_preferences/resend_verification/:id
  def resend_verification
    @channel = current_user.notification_channels.find(params[:id])
    
    if @channel.send_verification
      flash[:notice] = "Verification code sent successfully."
    else
      flash[:alert] = "Failed to send verification code. Please try again later."
    end
    
    redirect_to notification_preferences_path
  end
  
  # POST /notification_preferences/toggle_channel/:id
  def toggle_channel
    @channel = current_user.notification_channels.find(params[:id])
    
    if @channel.update(enabled: !@channel.enabled)
      flash[:notice] = "Notification channel #{@channel.enabled? ? 'enabled' : 'disabled'} successfully."
    else
      flash[:alert] = "Failed to update notification channel."
    end
    
    redirect_to notification_preferences_path
  end
  
  private
  
  # Set notification preference
  def set_notification_preference
    @notification_preference = current_user.notification_preference || current_user.create_notification_preference
  end
  
  # Strong parameters for notification preference
  def notification_preference_params
    params.require(:notification_preference).permit(
      :email_enabled, :sms_enabled, :push_enabled, :in_app_enabled,
      email_preferences: [:general, :security, :transaction, :account, :system],
      sms_preferences: [:security, :transaction],
      push_preferences: [:general, :security, :transaction, :account, :system],
      in_app_preferences: [:general, :security, :transaction, :account, :system]
    )
  end
  
  # Strong parameters for notification channel
  def channel_params
    params.require(:notification_channel).permit(:channel_type, :identifier)
  end
end
