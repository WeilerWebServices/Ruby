require 'test/spec'

require 'rack/mock'
require 'rack/methodoverride'
require 'stringio'

context "Rack::MethodOverride" do
  specify "should not affect GET requests" do
    env = Rack::MockRequest.env_for("/?_method=delete", :method => "GET")
    app = Rack::MethodOverride.new(lambda { |env| Rack::Request.new(env) })
    req = app.call(env)

    req.env["REQUEST_METHOD"].should.equal "GET"
  end

  specify "should modify REQUEST_METHOD for POST requests" do
    env = Rack::MockRequest.env_for("/", :method => "POST", :input => "_method=put")
    app = Rack::MethodOverride.new(lambda { |env| Rack::Request.new(env) })
    req = app.call(env)

    req.env["REQUEST_METHOD"].should.equal "PUT"
  end

  specify "should not modify REQUEST_METHOD if the method is unknown" do
    env = Rack::MockRequest.env_for("/", :method => "POST", :input => "_method=foo")
    app = Rack::MethodOverride.new(lambda { |env| Rack::Request.new(env) })
    req = app.call(env)

    req.env["REQUEST_METHOD"].should.equal "POST"
  end
end
