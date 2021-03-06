require 'test/spec'
require 'sinatra/base'
require 'sinatra/test'

describe "Middleware" do
  include Sinatra::Test

  before do
    @app = mock_app(Sinatra::Default) {
      get '/*' do
        response.headers['X-Tests'] = env['test.ran'].join(', ')
        env['PATH_INFO']
      end
    }
  end

  class MockMiddleware < Struct.new(:app)
    def call(env)
      (env['test.ran'] ||= []) << self.class.to_s
      app.call(env)
    end
  end

  class UpcaseMiddleware < MockMiddleware
    def call(env)
      env['PATH_INFO'] = env['PATH_INFO'].upcase
      super
    end
  end

  it "is added with Sinatra::Application.use" do
    @app.use UpcaseMiddleware
    get '/hello-world'
    response.should.be.ok
    body.should.equal '/HELLO-WORLD'
  end

  class DowncaseMiddleware < MockMiddleware
    def call(env)
      env['PATH_INFO'] = env['PATH_INFO'].downcase
      super
    end
  end

  specify "runs in the order defined" do
    @app.use UpcaseMiddleware
    @app.use DowncaseMiddleware
    get '/Foo'
    body.should.equal "/foo"
    response['X-Tests'].should.equal "UpcaseMiddleware, DowncaseMiddleware"
  end

  specify "resets the prebuilt pipeline when new middleware is added" do
    @app.use UpcaseMiddleware
    get '/Foo'
    body.should.equal "/FOO"
    @app.use DowncaseMiddleware
    get '/Foo'
    body.should.equal '/foo'
    response['X-Tests'].should.equal "UpcaseMiddleware, DowncaseMiddleware"
  end

end
