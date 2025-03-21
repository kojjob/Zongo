class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:check_avatar]
   def home
   end

   def theme_test
     # Just render the view
   end
   
   def check_avatar
     if current_user&.avatar&.attached?
       begin
         # Get the URL for the avatar
         avatar_url = rails_blob_url(current_user.avatar)
         # Try to get variant
         variant_url = url_for(current_user.avatar.variant(resize_to_fill: [100, 100]).processed)
         
         render json: {
           success: true,
           avatar_attached: true,
           avatar_url: avatar_url,
           variant_url: variant_url,
           content_type: current_user.avatar.content_type,
           byte_size: current_user.avatar.byte_size,
           created_at: current_user.avatar.created_at
         }
       rescue => e
         render json: {
           success: false, 
           avatar_attached: true,
           error: e.message,
           backtrace: e.backtrace.first(5)
         }
       end
     else
       render json: { success: false, avatar_attached: false, message: "No avatar attached to current user" }
     end
   end
end
