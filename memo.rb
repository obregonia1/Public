# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'

def h(text)
  Rack::Utils.escape_html(text)
end

def get_contains(id)
  JSON.parse(File.open("./memos/#{id}.json").read)
end

def write_memo(id, title, body)
  File.open("./memos/#{id}.json", 'w') do |file|
    hash = { title: title, body: body }
    JSON.dump(hash, file)
  end
end

Dir.mkdir('memos') unless Dir.exist?('./memos')

get '/' do
  redirect to('/memos')
end

get '/memos' do
  @page_title = 'メモ一覧'

  files = Dir.glob('./memos/*')
  files.sort_by! { |file| File.new(file).birthtime }
  @ids = files.map { |file| File.basename(file, '.*') }

  erb :top
end

get '/memos/new' do
  @page_title = 'メモを新規作成'

  erb :new_memo
end

post '/memos' do
  title = params[:title]
  body = params[:body]
  id = SecureRandom.uuid

  redirect to('/no_title_error') if params[:title].empty?

  write_memo(id, title, body)

  redirect to('/')
end

get '/memos/*/' do |id|
  @id = id
  @title = h(get_contains(id)['title'])
  @body = h(get_contains(id)['body']).gsub("\r\n", '<br>')
  @page_title = @title

  erb :memo_template
end

delete '/memos/*' do |id|
  path = "./memos/#{id}.json"
  File.delete(path)

  redirect to('/')
end

get '/memos/*/edit' do |id|
  @page_title = 'メモを編集'
  @id = id
  @title = get_contains(id)['title']
  @body = get_contains(id)['body']

  erb :memo_edit
end

patch '/memos/*' do |id|
  new_title = params[:title]
  new_body = params[:body]

  redirect to('/no_title_error') if params[:title].empty?

  write_memo(id, new_title, new_body)

  redirect to('/')
end

get '/no_title_error' do
  @page_title = 'エラー'

  erb %( <h2>タイトルを入力して下さい</h2> )
end
