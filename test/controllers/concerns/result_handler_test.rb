require 'test_helper'

class ResultHandlerTest < ActionController::TestCase
  class TestController < ActionController::Base
    include ResultHandler
    
    def success_redirect
      result = Result.success(message: "Operation successful", data: { id: 123 })
      handle_result(result, {
        success_message: "Custom success message",
        success_redirect: "/success"
      })
    end
    
    def success_render
      result = Result.success(message: "Operation successful", data: { id: 123 })
      handle_result(result, {
        success_message: "Custom success message",
        success_action: :render,
        render_options: { template: "test/success" }
      })
    end
    
    def success_json
      result = Result.success(message: "Operation successful", data: { id: 123 })
      handle_result(result, {
        success_action: :json
      })
    end
    
    def failure_redirect
      result = Result.failure(message: "Operation failed", code: :validation_error)
      handle_result(result, {
        failure_message: "Custom failure message",
        failure_redirect: "/error"
      })
    end
    
    def failure_render
      result = Result.failure(message: "Operation failed", code: :validation_error)
      handle_result(result, {
        failure_message: "Custom failure message",
        failure_action: :render,
        render_options: { template: "test/error" }
      })
    end
    
    def failure_json
      result = Result.failure(message: "Operation failed", code: :validation_error)
      handle_result(result, {
        failure_action: :json
      })
    end
    
    def with_block
      result = Result.success(data: { count: 5 })
      handle_result(result) do |data|
        @processed = "Processed #{data[:count]}"
      end
      render plain: @processed
    end
  end
  
  tests TestController
  
  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get 'success_redirect' => 'result_handler_test/test#success_redirect'
      get 'success_render' => 'result_handler_test/test#success_render'
      get 'success_json' => 'result_handler_test/test#success_json'
      get 'failure_redirect' => 'result_handler_test/test#failure_redirect'
      get 'failure_render' => 'result_handler_test/test#failure_render'
      get 'failure_json' => 'result_handler_test/test#failure_json'
      get 'with_block' => 'result_handler_test/test#with_block'
    end
  end
  
  test "handle_result redirects on success by default" do
    get :success_redirect
    
    assert_redirected_to "/success"
    assert_equal "Custom success message", flash[:notice]
  end
  
  test "handle_result renders on success when requested" do
    # Mocking render to avoid template not found errors
    @controller.expects(:render).with(template: "test/success")
    
    get :success_render
    
    assert_equal "Custom success message", flash[:notice]
  end
  
  test "handle_result renders JSON on success when requested" do
    get :success_json
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal true, json_response["success"]
    assert_equal 123, json_response["data"]["id"]
    assert_equal "Operation successful", json_response["message"]
  end
  
  test "handle_result redirects on failure by default" do
    get :failure_redirect
    
    assert_redirected_to "/error"
    assert_equal "Custom failure message", flash[:alert]
  end
  
  test "handle_result renders on failure when requested" do
    # Mocking render to avoid template not found errors
    @controller.expects(:render).with(template: "test/error")
    
    get :failure_render
    
    assert_equal "Custom failure message", flash[:alert]
  end
  
  test "handle_result renders JSON on failure when requested" do
    get :failure_json
    
    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal false, json_response["success"]
    assert_equal "Operation failed", json_response["error"]["message"]
    assert_equal "validation_error", json_response["error"]["code"]
  end
  
  test "handle_result executes block on success" do
    get :with_block
    
    assert_equal "Processed 5", response.body
  end
end
