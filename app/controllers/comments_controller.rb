class CommentsController < ApplicationController
  # 1. REMOVED allow_unauthenticated_access: Guests can no longer access the create endpoint
  # 2. REMOVED skip_forgery_protection: Restores full CSRF security tracking since only logged-in users use this form

  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.build(comment_params)

    # Automatically map the comment to the currently authenticated user session
    @comment.user_id = Current.user.id
    
    # Force new comments to be pending before hitting the database for administrative review
    @comment.status = :pending

    if @comment.save
      redirect_to article_path(@article), notice: "Comment submitted successfully! It will appear once approved by an administrator."
    else
      redirect_to article_path(@article), alert: "Could not save comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    # EXCLUSIVE SUPER ADMIN PERMISSION: Check if the current session user is an administrator
    if authenticated? && Current.user&.admin?
      @comment.destroy
      redirect_to article_path(@article), notice: "Comment was deleted successfully by Admin!", status: :see_other
      return
    end

    # TOTAL BLOCK FOR EVERYONE ELSE: Regular logged-in users and article authors are denied deletion rights
    redirect_to article_path(@article), alert: "Access Denied: Only a System Administrator can remove comments.", status: :unauthorized
  end

  private
    def comment_params
      params.require(:comment).permit(:body, :commenter)
    end
end