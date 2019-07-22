class ApplicationController < ActionController::API
  def hello
    render json: "hello"
  end
end
