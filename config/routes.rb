Rails.application.routes.draw do
  # User pages
  scope :user do
    root 'user#user_settings', as: :settings
    
    match 'logout' => 'user#user_logout', as: :logout, via: :all
    post 'update' => 'user#update_user_settings', as: :update_settings
    post 'find' => 'user#find_user', as: :find_user

    get 'update' => 'user#update', as: :oauth_update
    post 'save' => 'user#save', as: :oauth_save

    # User confirmation pages
    get '/confirm/:token' => 'user#confirm', as: :confirm
    post '/doconfirm' => 'user#do_confirm', as: :do_confirm
  end

  # OAuth enpoints
  scope :oauth do
    match 'callback' => 'user#callback', via: :all, as: :oauth_callback
    get ':provider' => 'user#oauth', as: :auth_at_provider
  end

end
