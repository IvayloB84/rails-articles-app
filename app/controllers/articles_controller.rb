class ArticlesController < ApplicationController
  # 1. Tells Rails 8 which pages guests can view without logging in
  allow_unauthenticated_access only: [ :index, :show ]
  
  before_action :resume_session

  # 2. Intercepts modification requests to run authorship authorization checks
  before_action :ensure_author, only: [ :edit, :update, :destroy ]

  def index
    if params[:search].present?
      # Case-insensitive term search filtering both columns in 1 single fast query statement
      @articles = Article.where("title LIKE ? OR body LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%").latest
    else
      @articles = Article.latest
    end
  end

  def show
    @article = Article.find(params[:id])
    @admin_usernames = User.where(admin: true).pluck(:username)

    # Natively configuration parameters for pagination limits
    @per_page = 5
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1
    offset = (@page - 1) * @per_page

    # 1. Load the base authorized scope query context based on session rights
    base_scope = if authenticated? && Current.user&.admin?
                   @article.comments.where.not(status: :rejected)
                 elsif authenticated?
                   @article.comments.where(status: :approved)
                                    .or(@article.comments.where(status: :pending, commenter: Current.user.username))
                 else
                   @article.comments.approved
                 end

    # 2. Extract total record lengths cleanly to calculate page maximum thresholds
    @total_comments = base_scope.count
    @total_pages = (@total_comments.to_f / @per_page).ceil
    @total_pages = 1 if @total_pages < 1

    # 3. Apply native pagination limits and offsets directly onto the final query
    @comments = base_scope.order(created_at: :desc).limit(@per_page).offset(offset)
  end

  def new
    @article = Article.new
  end

  def create
    # 1. Build the base text fields without images first
    @article = Current.user.articles.build(article_params.except(:images))
    
    if @article.save
      # 2. Securely append the multiple images array to the article if attached
      @article.images.attach(params[:article][:images]) if params[:article][:images].present?
      redirect_to articles_path, notice: "Article published successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @article is already loaded by the before_action filter safely
  end

  def update
    if params[:article][:purge_image_ids].present?
      params[:article][:purge_image_ids].each do |img_id|
        @article.images.find_by(id: img_id)&.purge
      end
    end

    if params[:article][:images].present?
      @article.images.attach(params[:article][:images])
    end

    if @article.update(article_params.except(:purge_image_ids, :images))
      redirect_to article_path(@article), notice: "Article updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path, notice: "Article deleted permanently!", status: :see_other
  end

  private
    def article_params
      params.expect(article: [ :title, :body, purge_image_ids: [], images: [] ])
    end

    def ensure_author
      @article = Article.find(params[:id])
      
      return if Current.user&.admin?
      
      # If not an admin, restrict modification access strictly to the true author
      if Current.user.nil? || @article.user_id != Current.user.id
        redirect_to articles_path, alert: "Access Denied: You are not authorized to modify this article."
      end
    end
end