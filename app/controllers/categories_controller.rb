class CategoriesController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :authorize_admin!, except: [ :index, :show ]
  before_action :set_category, only: [ :show, :edit, :update, :destroy ]

  # GET /categories
  def index
    @categories = Category.all.order(:display_order, :name)
  end

  # GET /categories/:id
  def show
    @events = @category.events.upcoming.order(start_time: :asc).paginate(page: params[:page], per_page: 12)
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # POST /categories
  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to @category, notice: "Category created successfully!"
    else
      render :new
    end
  end

  # GET /categories/:id/edit
  def edit
  end

  # PATCH/PUT /categories/:id
  def update
    if @category.update(category_params)
      redirect_to @category, notice: "Category updated successfully!"
    else
      render :edit
    end
  end

  # DELETE /categories/:id
  def destroy
    if @category.events.exists?
      redirect_to categories_path, alert: "Cannot delete category with associated events."
    else
      @category.destroy
      redirect_to categories_path, notice: "Category deleted successfully!"
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :icon, :color_code, :description, :display_order)
  end

  def authorize_admin!
    # Implement admin authorization based on your app's needs
    unless current_user.admin?
      redirect_to categories_path, alert: "You don't have permission to manage categories."
    end
  end
end
