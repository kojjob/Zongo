class AgricultureResourcesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_resource, only: [:show, :edit, :update, :destroy]
  before_action :ensure_admin, only: [:new, :create, :edit, :update, :destroy]
  
  def index
    redirect_to resources_agriculture_path
  end
  
  def show
    # Increment view count
    @resource.increment_view_count!
    
    # Get related resources
    @related_resources = @resource.related_resources(3)
    
    # Get other resources by type
    @similar_resources = AgricultureResource.published
                                           .where(resource_type: @resource.resource_type)
                                           .where.not(id: @resource.id)
                                           .limit(3)
  end
  
  def new
    @resource = AgricultureResource.new
    @crops = Crop.all.order(:name)
  end
  
  def create
    @resource = AgricultureResource.new(resource_params)
    @resource.user = current_user
    
    if @resource.save
      redirect_to @resource, notice: 'Resource was successfully created.'
    else
      @crops = Crop.all.order(:name)
      render :new
    end
  end
  
  def edit
    @crops = Crop.all.order(:name)
  end
  
  def update
    if @resource.update(resource_params)
      redirect_to @resource, notice: 'Resource was successfully updated.'
    else
      @crops = Crop.all.order(:name)
      render :edit
    end
  end
  
  def destroy
    @resource.destroy
    redirect_to resources_agriculture_path, notice: 'Resource was successfully deleted.'
  end
  
  private
  
  def set_resource
    @resource = AgricultureResource.find(params[:id])
  end
  
  def ensure_admin
    unless current_user.admin?
      redirect_to resources_agriculture_path, alert: 'You are not authorized to perform this action.'
    end
  end
  
  def resource_params
    params.require(:agriculture_resource).permit(
      :title, :content, :crop_id, :resource_type, :published, 
      :featured, :external_url, :video_url, :tags, 
      :thumbnail, :document, images: []
    )
  end
end
