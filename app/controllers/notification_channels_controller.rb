class NotificationChannelsController < ApplicationController
  before_action :authenticate_user!, except: [:verify]
  before_action :set_channel, only: [:destroy, :toggle, :resend_verification]
  
  # GET /notification_channels/verify/:token
  def verify
    token = params[:token]
    
    # Find channel by verification token
    channel = NotificationChannel.find_by(verification_token: token)
    
    if channel&.verify_with_token(token)
      flash[:notice] = "Your notification channel has been verified successfully."
      
      # Redirect to login if not authenticated
      if current_user
        redirect_to notification_preferences_path
      else
        redirect_to new_user_session_path
      end
    else
      flash[:alert] = "Invalid or expired verification token."
      redirect_to root_path
    end
  end
  
  # POST /notification_channels
  def create
    @channel = current_user.notification_channels.new(channel_params)
    
    if @channel.save
      # Send verification if needed
      @channel.send_verification if @channel.channel_type.in?(['email', 'sms'])
      
      respond_to do |format|
        format.html do
          flash[:notice] = "Notification channel added successfully. Please verify it to receive notifications."
          redirect_to notification_preferences_path
        end
        format.json { render json: @channel, status: :created }
        format.turbo_stream { render turbo_stream: turbo_stream.append("notification_channels", partial: "notification_preferences/channel", locals: { channel: @channel }) }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Failed to add notification channel: #{@channel.errors.full_messages.join(', ')}"
          redirect_to notification_preferences_path
        end
        format.json { render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_channel_form", partial: "notification_preferences/new_channel_form", locals: { channel: @channel }) }
      end
    end
  end
  
  # DELETE /notification_channels/:id
  def destroy
    if @channel.destroy
      respond_to do |format|
        format.html do
          flash[:notice] = "Notification channel removed successfully."
          redirect_to notification_preferences_path
        end
        format.json { head :no_content }
        format.turbo_stream { render turbo_stream: turbo_stream.remove("channel_#{@channel.id}") }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Failed to remove notification channel."
          redirect_to notification_preferences_path
        end
        format.json { render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  
  # PATCH /notification_channels/:id/toggle
  def toggle
    if @channel.update(enabled: !@channel.enabled)
      respond_to do |format|
        format.html do
          flash[:notice] = "Notification channel #{@channel.enabled? ? 'enabled' : 'disabled'} successfully."
          redirect_to notification_preferences_path
        end
        format.json { render json: @channel }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("channel_#{@channel.id}", partial: "notification_preferences/channel", locals: { channel: @channel }) }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Failed to update notification channel."
          redirect_to notification_preferences_path
        end
        format.json { render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  
  # POST /notification_channels/:id/resend_verification
  def resend_verification
    if @channel.send_verification
      respond_to do |format|
        format.html do
          flash[:notice] = "Verification code sent successfully."
          redirect_to notification_preferences_path
        end
        format.json { render json: { success: true } }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("channel_#{@channel.id}", partial: "notification_preferences/channel", locals: { channel: @channel }) }
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Failed to send verification code. Please try again later."
          redirect_to notification_preferences_path
        end
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  # Set channel from params
  def set_channel
    @channel = current_user.notification_channels.find(params[:id])
  end
  
  # Strong parameters for notification channel
  def channel_params
    params.require(:notification_channel).permit(:channel_type, :identifier)
  end
end
