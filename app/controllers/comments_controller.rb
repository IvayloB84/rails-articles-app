class CommentsController < ApplicationController
  # REMOVED allow_unauthenticated_access to completely block guest submissions
  # REMOVED skip_forgery_protection to restore strict session forgery security parameters

  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.build(comment_params)

    # Enforce user association since only authenticated users can access this action now
    @comment.user_id = Current.user.id
    @comment.status = :pending

    if @comment.save
      redirect_to article_path(@article), notice: "Comment posted successfully! It will appear once approved by an administrator."
    else
      redirect_to article_path(@article), alert: "Could not save comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    # Exclusive Admin Check: Bypasses everything silently and processes deletion
    if authenticated? && Current.user&.admin?
      @comment.destroy
      redirect_to article_path(@article), notice: "Comment deleted successfully.", status: :see_other
      return
    end

    # SILENT REFUSAL: Redirects normal users and avoids rendering a broken 401 local browser screen
    redirect_to article_path(@article), status: :see_other
  end

  private
    def comment_params
      params.require(:comment).permit(:body, :commenter)
    end
end