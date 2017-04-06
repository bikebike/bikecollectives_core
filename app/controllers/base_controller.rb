class BaseController < ActionController::Base
  protect_from_forgery with: :exception

  rescue_from ActiveRecord::RecordNotFound do |exception|
    do_404
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    do_403
  end

  rescue_from AbstractController::ActionNotFound do |exception|
    do_403
  end

  def robots
    render text: File.read("config/robots-#{Rails.env.production? ? 'live' : 'dev'}.txt"), content_type: 'text/plain'
  end

  def humans
    render text: File.read("config/humans.txt"), content_type: 'text/plain'
  end

  def do_404
    error_404(status: 404)
  end

  def error_404(args = {})
    render 'application/404', args
  end

  def confirmation_sent(user)
    do_403 'login_confirmation_sent'
  end

  def do_403(template = nil)
    @template = template
    render 'application/permission_denied', status: 403
  end

  def error_500(exception = nil)
    render 'application/500', status: 500
  end

  def confirm(uid = nil)
    @confirmation = EmailConfirmation.find_by_token(params[:token])

    unless @confirmation.present?
      @token_not_found = true
      return do_404
    end

    confirm_user = nil
    if uid.is_a?(User)
      confirm_user = uid
      uid = confirm_user.id
    end

    # check to see if we were given a user id to confirm against
    #  if we were, make sure it was the same one
    if (uid ||= (params[:uid] || session[:confirm_uid]))
      if uid == @confirmation.user_id
        session[:uid] = nil
        confirm_user ||= User.find uid
        auto_login(confirm_user)
      else
        @confirmation.delete
      end

      redirect_to (@confirmation.url || '/')
      return
    end

    @banner_image = 'grafitti.jpg'
    @page_title = 'page_titles.403.Please_Confirm_Email'
    do_403 'login_confirm'
  end

protected

  def confirm_email(email, token, dest)
    if email
      # see if we've already sent the confirmation email and are just confirming
      #  the email address
      if token
        user = User.find_user(email)
        confirm(user)
        return
      end
      user = User.get(email)

      # generate the confirmation, send the email and show the 403
      generate_confirmation(user, dest)

      confirmation_sent(user)
      return
    end
    
    do_403 if request.post?

    do_404
  end

  def generate_confirmation(user, url, expiry = nil)
    if user.is_a? String
      user = User.find_user(user)

      # if the user doesn't exist, just show them a 403
      do_403 unless user.present?
    end
    expiry ||= (Time.now + 12.hours)
    session[:confirm_uid] = user.id

    unless user.locale.present?
      user.locale = I18n.locale
      user.save
    end

    # send the confirmation email and make sure it get sent as quickly as possible
    send_confirmation(EmailConfirmation.create(user_id: user.id, expiry: expiry, url: url))
  end
end
