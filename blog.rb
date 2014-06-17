require 'sinatra'
require 'slim'
require 'dm-core'
require 'dm-timestamps'
require 'dm-migrations'
require 'dm-validations'

#Model
DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite://", settings.root, "/dev.db"))


class Post
	include DataMapper::Resource

	property :id, Serial	
	property :title, String, :required => true
	property :alias, String, default: -> r,p { r.make_pretty }
	property :body, Text, :required => true
	property :created_at, DateTime
	property :updated_at, DateTime

	def make_pretty
  		self.alias = title.downcase.gsub(/\W/,'-').squeeze('-').chomp('-')
	end
end

#DataMapper.auto_migrate!
DataMapper.finalize
#Function for truncate long posts
def truncate_words(text, length, end_string = ' ... ')
  unless text.nil?
  	words = text.split()
  	words = words[0...length].join(' ') + (words.length > length ? end_string : ' ')
  end
end

#Set root directory
set :root, './'


#Some helpers
helpers do
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="Retricted area, need authorization")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.username && @auth.credentials == ['admin', '12345']
  end
end

before '/admin/*' do
  protected!
end


get '/' do
	redirect '/all'
end

get '/all' do
	@PageTitle = 'MyLittleBlog'
	@Posts = Post.all
	slim :"/posts/index"
end

get '/posts/:id' do
	@Post = Post.first(id: params[:id])
	@PageTitle = @Post.title
	slim :"/posts/show"
end

#show out posts via cute alias
get "/show/:alias" do
    @Post = Post.first(alias: params[:alias])
    @PageTitle = @Post.title
    slim :"/posts/show"
end

#Admin's actions
get '/admin/all' do
	@PageTitle = 'MyLittleBlog'
	@Posts = Post.all
	slim :"/posts/pages"
end

get '/admin/create' do
	slim :"/posts/create"
end

post '/admin/create' do
	params.delete 'submit'
	params[:updated_at] = params[:created_at] = Time.now
	@Post = Post.new(params)
	if @Post.save		
	redirect '/admin/all'
	else
	puts @Post
	redirect 'admin/create'
	end	
end

get '/admin/edit/:id' do
	@Post= Post.get(params[:id])
	slim :"posts/edit"
end

post '/admin/edit/:id' do	
	@Post = Post.get(params[:id])
	params.delete 'submit'
  	params.delete 'id'
  	params.delete 'splat'
  	params.delete 'captures'
  	params[:updated_at] = Time.now
  	@Post.attributes = params
  	
	if @Post.save
		redirect "/admin/all"
	else
		redirect "/admin/edit/#{@Post.id}}"
	end
end

get '/admin/delete/:id' do
	Post.get(params[:id]).destroy
	redirect '/admin/all'
end
