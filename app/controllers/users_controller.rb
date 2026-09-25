class UsersController < ApplicationController
  allow_unauthenticated_access only: [ :show ]
  before_action :resume_session, only: [ :show, :update ]

  def show
    @user = User.find_by!(username: params[:username])
    @articles = @user.articles.order(created_at: :desc)
    @comments = Comment.where(commenter: @user.username, status: :approved).order(created_at: :desc)
  end

  def update
    @user = User.find_by!(username: params[:username])
    
    # Security checkpoint: Prevent users from editing profiles that do not belong to them
    if authenticated? && Current.user == @user
      if @user.update(user_params)
        redirect_to user_path(@user.username), notice: "Biography updated successfully."
      else
        redirect_to user_path(@user.username), alert: "Could not save bio update."
      end
    else
      redirect_to root_path, alert: "Access Denied: Action unauthorized."
    end
  end

  private
    def user_params
      params.require(:user).permit(:bio)
    end
end