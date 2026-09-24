class Admin::CommentsController < ApplicationController
  # Force session validation and restrict access to administrators only
  before_action :resume_session
  before_action :ensure_admin

  def index
    @pending_comments = Comment.pending.order(created_at: :desc)
  end

  def approve
    @comment = Comment.find(params[:id])
    @comment.approved!
    redirect_to admin_comments_path, notice: "Comment was approved and published successfully."
  end

  def reject
    @comment = Comment.find(params[:id])
    @comment.rejected!
    redirect_to admin_comments_path, notice: "Comment was rejected and hidden from public feed."
  end

  private
    def ensure_admin
      unless authenticated? && Current.user&.admin?
        redirect_to root_path, alert: "Access Denied: Administrative privileges required."
      end
    end
end