require 'helper'

# this test suite assumes that the Sandbox API 
# deployed at ENV['STACKMOB_TEST_URL'] has an object
# model created of type "user" and that the application
# name is "test"

class StackMobClientIntegrationTest < MiniTest::Unit::TestCase


  attr_reader :sm_url, :sm_key, :sm_secret

  MISSING_URL_ERR_MSG = "!! ABORTED: You must define the STACKMOB_TEST_URL environment variable in order to run this suite" 

  def sm_app_vsn
    0
  end
  
  def sm_app_name
    "test"
  end

  def setup
    set_sm_url!
    set_sm_consumer_key
    set_sm_consumer_secret

    @valid_client = StackMob::Client.new(sm_url, sm_app_name, sm_app_vsn, sm_key, sm_secret)
  end

  def test_valid_get_path
    api_result_hash = @valid_client.request(:get, :api, "/listapi")
    assert api_result_hash.has_key?("user")
  end

  def test_get_path_without_prepending_slash
    res = @valid_client.request(:get, :api, "listapi")
    assert res.has_key?("user")
  end

  def test_invalid_get_path_raises_error
    assert_raises StackMob::Client::RequestError do 
      @valid_client.request(:get, :api, "/dne")
    end
  end

  def test_user_object_lifecycle
    user_id = "123"
    user_name = "StackMob Test"

    @valid_client.request(:delete, :api, "/user", :user_id => user_id) # delete the object in case it exists already

    @valid_client.request(:post, :api, "/user", :user_id => user_id, :name => user_name)

    assert_equal user_name, @valid_client.request(:get, :api, "/user", :user_id => user_id).first['name']
    
    @valid_client.request(:put, :api, "/user", :user_id => user_id, :name => user_name + "updated")
    
    assert_equal (user_name + "updated"), @valid_client.request(:get, :api, "/user", :user_id => user_id).first['name']

  end

  private

  # SHOULD THE EXIT REQUIREMENTS BE MOVED TO THE HELPER IF POSSIBLE?
  def set_sm_url! 
    if !(@sm_url = ENV['STACKMOB_TEST_URL']) then
      puts MISSING_URL_ERR_MSG
      exit
    end
  end

  # SHOULD WE FORCE THESE TO BE ENVIRONMENT VARIABLES AS WELL?
  # IT WOULD PREVENT THIS SUITE FROM BEING RUN WITH MOST LIKELY
  # BAD CREDENTIALS, BUT WONT PREVENT IT ALTOGETHER
  def set_sm_consumer_key
    @sm_key = ENV['STACKMOB_TEST_KEY'] || "b0b4b19e-2901-4b3b-b8a7-67338d2b5cb3"
  end

  def set_sm_consumer_secret
    @sm_secret = ENV['STACKMOB_TEST_SECRET'] || "b3764a11-cdcb-4750-9aad-cee0b6201d0c"
  end

end