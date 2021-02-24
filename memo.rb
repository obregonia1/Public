# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'securerandom'

enable :method_override

CONN = PG.connect(dbname: 'memoapp')

create_str = 'CREATE TABLE if not exists memolist (id text not null unique, title text not null unique, body text)'
CONN.exec(create_str)

add_str = 'INSERT into memolist (id,title,body) values ($1,$2,$3)'
CONN.prepare('add_memo', add_str)

update_str = 'UPDATE memolist set title=$1, body=$2 where id=$3'
CONN.prepare('update_memo', update_str)

get_title_str = 'SELECT title from memolist where id=$1'
CONN.prepare('get_title', get_title_str)

def h(text)
  Rack::Utils.escape_html(text)
end

def get_body(id)
  select_str = "SELECT body from memolist where id='#{id}'"
  CONN.prepare('get_body', select_str)
  CONN.exec_prepared('get_body').values[0][0]
end

def get_title(id)
  CONN.exec_prepared('get_title', [id]).values[0]
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

get '/new' do
  @page_title = 'メモを新規作成'

  erb :new_memo
end

post '/create' do
  @title = params[:title]
  @body = params[:body]

  redirect to('/no_title_error') if params[:title].empty?

  CONN.exec_prepared('add_memo', [@title.to_s, @body.to_s])

  redirect to('/')
end

get '/memos/*/' do |title|
  @page_title = title
  @title = h(title)
  @body = h(get_body(title)).gsub(/\R/, '<br>')

  erb :memo_template
end

delete '/memos/*/delete' do |title|
  delete_str = "DELETE from memolist where title='#{title}'"
  CONN.exec(delete_str)

  redirect to('/')
end

get '/memos/*/edit' do |title|
  @page_title = 'メモを編集'
  @title = title
  @body = get_body(title)

  erb :memo_edit
end

patch '/memos/*/update' do |title|
  @new_title = params[:title]
  @new_body = params[:body]

  redirect to('/no_title_error') if params[:title].empty?

  CONN.exec_prepared('update_memo', [@new_title.to_s, @new_body.to_s, title.to_s])

  redirect to('/')
end

get '/no_title_error' do
  @page_title = 'エラー'

  erb %( <h2>タイトルを入力して下さい</h2> )
end
