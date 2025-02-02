class ApplicationController < ActionController::API
  before_action :set_cors_headers

   private


  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*'
  end


end
