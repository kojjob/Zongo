class CommunityController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @page_title = "Community"
    @featured_groups = Group.featured.limit(6)
    @upcoming_gatherings = Gathering.upcoming.limit(4)
  end

  def groups
    @page_title = "Local Groups"
    @categories = GroupCategory.all
    @featured_groups = Group.featured.limit(6)
    @popular_groups = Group.popular.limit(8)
    @my_groups = current_user.groups.limit(4) if user_signed_in?
  end

  def gatherings
    @page_title = "Local Gatherings"
    @upcoming_gatherings = Gathering.upcoming.limit(8)
    @past_gatherings = Gathering.past.limit(4)
    @my_gatherings = current_user.gatherings.upcoming.limit(4) if user_signed_in?
  end

  def search_groups
    @query = params[:query]
    @category_id = params[:category_id]
    
    @groups = Group.all
    @groups = @groups.where("name ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%") if @query.present?
    @groups = @groups.where(group_category_id: @category_id) if @category_id.present?
    @groups = @groups.limit(20)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to community_groups_path }
    end
  end

  def search_gatherings
    @query = params[:query]
    @date = params[:date]
    
    @gatherings = Gathering.upcoming
    @gatherings = @gatherings.where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%") if @query.present?
    @gatherings = @gatherings.where("date >= ?", @date) if @date.present?
    @gatherings = @gatherings.limit(20)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to community_gatherings_path }
    end
  end

  def join_group
    @group_id = params[:group_id]
    
    # In a real implementation, this would create a membership
    flash[:notice] = "You have successfully joined the group!"
    
    respond_to do |format|
      format.html { redirect_to community_groups_path }
      format.turbo_stream
    end
  end

  def attend_gathering
    @gathering_id = params[:gathering_id]
    
    # In a real implementation, this would create an attendance
    flash[:notice] = "You are now attending this gathering!"
    
    respond_to do |format|
      format.html { redirect_to community_gatherings_path }
      format.turbo_stream
    end
  end
end
