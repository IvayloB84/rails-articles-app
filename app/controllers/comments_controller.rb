class CommentsController < ApplicationController
  # Allow anonymous users to post, but NOT to delete
  allow_unauthenticated_access only: [ :create ]
  skip_forgery_protection only: [ :create ]

  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.build(comment_params)

    if @comment.save
      redirect_to article_path(@article), notice: "Comment posted successfully!"
    else
      redirect_to article_path(@article), alert: "Could not save comment: #{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])

    comment_author = @comment.respond_to?(:user) ? @comment.user : nil

    if comment_author&.admin? && !authenticated_user&.admin?
      redirect_to article_path(@article), alert: "Security Error: You cannot delete an Administrator's comment.", status: :unauthorized
      return
    end

    is_admin = authenticated_user&.admin?
    is_article_owner = authenticated? && (authenticated_user == @article.user)

    if is_admin || is_article_owner
      @comment.destroy
      redirect_to article_path(@article), notice: "Comment was deleted successfully!", status: :see_other
    else
      redirect_to article_path(@article), alert: "You are not authorized to delete this comment.", status: :unauthorized
    end
  end

  private
    def comment_params
      params.require(:comment).permit(:body, :commenter)
    end
end