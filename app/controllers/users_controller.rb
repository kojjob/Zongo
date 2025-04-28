class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def become_seller
    current_user.update(seller: true)
    redirect_to dashboard_path, notice: "Congratulations! You are now a seller on Super Ghana."
  end
end
