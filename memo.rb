require 'sinatra'
require 'sinatra/reloader'

enable :method_override

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

get '/' do
  @page_title = 'top'
  titles = Dir.glob('./memos/*').map {|file| File.basename(file,'.*')}

  erb %{
  <form action="/new" method="get">
  <input type="submit" value="新規メモを作成">
  </form>
  <ul>
    <% #{titles}.map do |title| %>
    <li><a href="/memos/<%= title %>/"><%= title %></a></li>
    <% end %>
  </ul>
  }
end

get '/new' do
  @page_title = 'メモを新規作成'

  erb :new_memo
end

post '/create' do
  @title = params[:title]
  @body = params[:body]

  redirect to('/no_title_error') if params[:title].empty?

  Dir.mkdir('memos') unless Dir.exist?('./memos')
  open("./memos/#{@title}.txt", 'w') { |f| f.puts "#{@body}" }

  redirect to('/')
end

get '/memos/*/' do |title|
  @title = title
  @body = File.open("./memos/#{title}.txt") { |f| f.read }.gsub("\r\n","<br>")

  erb :memo_template
end

delete '/memos/*/delete' do |title|
  File.delete("./memos/#{title}.txt")

  redirect to('/')
end

get '/memos/*/edit' do |title|
  @page_title = 'メモを編集'
  @title = title

  erb :memo_edit
end

patch '/memos/*/update' do |title|
  @new_title = params[:title]
  @new_body = params[:body]

  redirect to('/no_title_error') if params[:title].empty?
  open("./memos/#{title}.txt", 'w') { |f| f.puts "#{@new_body}" }
  File.rename("./memos/#{title}.txt", "./memos/#{@new_title}.txt")

  redirect to('/')
end

get '/no_title_error' do
  @page_title = 'エラー'

  erb %{ <h2>タイトルを入力して下さい</h2> }
end
