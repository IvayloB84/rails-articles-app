module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session.present?
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      return Current.session if Current.session

      if session_record = find_session_by_cookie
        # TIMEOUT CHECK: Verify if the database session token was untouched for more than 30 minutes
        if session_record.updated_at < 30.minutes.ago
          session_record.destroy
          cookies.delete(:session_id)
          nil
        else
          # Natively touch the record to update its updated_at timestamp clock for this request
          session_record.touch
          Current.session = session_record
        end
      end
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      # If an active session expired via timeout, give the user a clear explanation badge alert
      flash[:alert] = "Your session has expired due to inactivity. Please sign in again." if cookies.signed[:session_id]
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        # REMOVED `.permanent`: Changing this allows the browser to clear the wrapper handle if the browser process is shut down completely
        cookies.signed[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      cookies.delete(:session_id)
    end
end