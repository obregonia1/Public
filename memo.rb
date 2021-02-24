# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'securerandom'

enable :method_override

CONN = PG.connect(dbname: 'memoapp')

create_str = 'CREATE TABLE if not exists memolist (id text not null unique, title text not null, body text)'
CONN.exec(create_str)

add_str = 'INSERT into memolist (id,title,body) values ($1,$2,$3)'
CONN.prepare('add_memo', add_str)

update_str = 'UPDATE memolist set title=$1, body=$2 where id=$3'
CONN.prepare('update_memo', update_str)

get_memo_str = 'SELECT * from memolist where id=$1'
CONN.prepare('get_memo', get_memo_str)

def h(text)
  Rack::Utils.escape_html(text)
end

def get_body(id)
  CONN.exec_prepared('get_memo', [id])[0]['body']
end

def get_title(id)
  CONN.exec_prepared('get_memo', [id])[0]['title']
end

get '/' do
  redirect to('/memos')
end

get '/memos' do
  @page_title = 'メモ一覧'
  ids = CONN.exec('SELECT id FROM memolist').map { |res| res.values[0] }
  @memos = {}
  ids.each do |id|
    @memos[id] = get_title(id)
  end

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

  CONN.exec_prepared('add_memo', [id, title, body])

  redirect to('/')
end

get '/memos/:id/' do |id|
  @id = id
  @title = @page_title = h(get_title(id))
  @body = h(get_body(id)).gsub(/\R/, '<br>')

  erb :memo_template
end

delete '/memos/:id/delete' do |id|
  delete_str = "DELETE from memolist where id='#{id}'"
  CONN.exec(delete_str)

  redirect to('/')
end

get '/memos/:id/edit' do |id|
  @page_title = 'メモを編集'
  @id = id
  @title = get_title(id)
  @body = get_body(id)

  erb :memo_edit
end

patch '/memos/:id/update' do |id|
  new_title = params[:title]
  new_body = params[:body]

  redirect to('/no_title_error') if params[:title].empty?

  CONN.exec_prepared('update_memo', [new_title, new_body, id])

  redirect to('/')
end

get '/no_title_error' do
  @page_title = 'エラー'

  erb %( <h2>タイトルを入力して下さい</h2> )
end
