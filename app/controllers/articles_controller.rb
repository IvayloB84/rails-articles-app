class ArticlesController < ApplicationController
  # 1. Tells Rails 8 which pages guests can view without logging in
  allow_unauthenticated_access only: [ :index, :show ]
  
  before_action :resume_session, only: [ :index, :show ]
  
  # 2. Intercepts modification requests to run structural authorization checks
  before_action :ensure_author, only: [ :edit, :update, :destroy ]

  def index
    if params[:search].present?
      @articles = Article.where("title LIKE ? OR body LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%").latest
    else
      @articles = Article.latest
    end
  end

  def show
    @article = Article.find(params[:id])
    @admin_usernames = User.where(admin: true).pluck(:username)

    @per_page = 5
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1
    offset = (@page - 1) * @per_page

    base_scope = if authenticated? && Current.user&.admin?
                   @article.comments.where.not(status: :rejected)
                 elsif authenticated?
                   @article.comments.where(status: :approved)
                                    .or(@article.comments.where(status: :pending, commenter: Current.user.username))
                 else
                   @article.comments.approved
                 end

    @total_comments = base_scope.count
    @total_pages = (@total_comments.to_f / @per_page).ceil
    @total_pages = 1 if @total_pages < 1

    @comments = base_scope.order(created_at: :desc).limit(@per_page).offset(offset)
  end

  def new
    @article = Article.new
  end

  def create
    uploaded_images = params.dig(:article, :images)

    @article = Current.user.articles.build(article_params.except(:images, :purge_image_ids))
    
    ActiveRecord::Base.transaction do
      if @article.save
        if uploaded_images.present?
          clean_images = Array(uploaded_images).reject(&:blank?)
          @article.images.attach(clean_images) if clean_images.any?
        end
        
        redirect_to articles_path, notice: "Article published successfully!"
        return
      else
        raise ActiveRecord::Rollback
      end
    end

    render :new, status: :unprocessable_entity
  end

  def edit
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
      # Standard array structures work seamlessly with ActiveStorage multi-upload keys
      params.expect(article: [ :title, :body, purge_image_ids: [], images: [] ])
    end

    def ensure_author
      @article = Article.find(params[:id])
      
      # Manually look up session context from secure cookies if Current.user hasn't booted yet
      active_session = Current.session || (Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id])
      logged_in_user = active_session&.user

      # 1. **SUPER ADMIN OVERRIDE**: Admins bypass all gates for any action
      return if logged_in_user&.admin?

      # 2. **DELETION GATE**: Block creators completely from reaching the destroy action
      if action_name == "destroy"
        redirect_to articles_path, alert: "Access Denied: Only a System Administrator possesses the authority to delete articles."
        return
      end
      
      # 3. Regular Edit/Update author validation logic
      if logged_in_user.nil? || @article.user_id != logged_in_user.id
        redirect_to articles_path, alert: "Access Denied: You are not authorized to modify this article."
      end
    end
end