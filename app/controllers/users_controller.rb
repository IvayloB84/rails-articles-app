class UsersController < ApplicationController
  # Allow public viewing of profile timelines, but resume sessions to check active identity states
  allow_unauthenticated_access only: [ :show ]
  before_action :resume_session, only: [ :show ]

  def show
    # Natively find the target user using your dynamic username parameter row hook
    @user = User.find_by!(username: params[:username])
    
    # Load all approved articles published by this profile timeline
    @articles = @user.articles.order(created_at: :desc)
    
    # Load all approved comments left by this profile across the website
    @comments = Comment.where(commenter: @user.username, status: :approved).order(created_at: :desc)
  end
end