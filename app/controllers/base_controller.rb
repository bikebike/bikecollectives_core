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
end
