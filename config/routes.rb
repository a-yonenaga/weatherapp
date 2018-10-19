Rails.application.routes.draw do
  get 'welcome/index' => redirect("/city/")

  root 'welcome#index'
  get '/city,:p,:c' => 'welcome#index'
  get '/coord,:lat,:lon' => 'welcome#red' , :constraints => {:lat=>/[0-9.]+/, :lon=>/[0-9.]+/}
end
