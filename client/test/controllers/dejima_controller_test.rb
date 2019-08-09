require 'test_helper'

class DejimaControllerTest < ActionDispatch::IntegrationTest
  test "should get create_user" do
    get dejima_create_user_url
    assert_response :success
  end

end
