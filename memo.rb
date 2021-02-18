# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'

enable :method_override

def h(text)
  Rack::Utils.escape_html(text)
end

def fname_to_id(fname)
  %r{^./memos/(\d)+_}.match(fname)
end

def id_to_title(id)
  memo_path = Dir.glob("./memos/#{id}_*").to_s
  File.basename(memo_path, '.*').split(/^\d+_/)[1]
end

def write_body(title, body)
  open("./memos/#{title}.txt", 'w') { |f| f.puts body }
end

def make_path(id, title)
  "./memos/#{id}_#{title}.txt"
end

def id_formatter(id)
  format('%03d', id)
end

Dir.mkdir('memos') unless Dir.exist?('./memos')

id = if Dir.empty?('./memos')
       0
     else
       last_name = Dir.glob('./memos/*').last
       fname_to_id(last_name)[1].to_i
     end

get '/' do
  @page_title = 'top'
  @titles = Dir.glob('./memos/*').map { |file| File.basename(file, '.*') }

  erb :top
end

get '/new' do
  @page_title = 'メモを新規作成'

  erb :new_memo
end

post '/memos' do
  @title = params[:title].tr('/', '-')
  @body = params[:body]
  id += 1
  format_id = id_formatter(id)

  redirect to('/no_title_error') if params[:title].empty?

  write_body("#{format_id}_#{@title}", @body)

  redirect to('/')
end

get '/memos/*/' do |id|
  @id = id
  @title = h(id_to_title(id))
  @body = h(File.open(make_path(id, @title), &:read)).gsub("\r\n", '<br>')
  @page_title = @title

  erb :memo_template
end

delete '/memos/*/delete' do |id|
  title = id_to_title(id)
  File.delete(make_path(id, title))

  redirect to('/')
end

get '/memos/*/edit' do |id|
  @page_title = 'メモを編集'
  @id = id
  @title = id_to_title(id)
  @body = File.open(make_path(id, @title), &:read)

  erb :memo_edit
end

patch '/memos/*/update' do |id|
  @new_title = params[:title]
  @new_body = params[:body]
  old_title = id_to_title(id)

  redirect to('/no_title_error') if params[:title].empty?

  write_body("#{id}_#{old_title}", @new_body)
  File.rename(make_path(id, old_title), make_path(id, @new_title))

  redirect to('/')
end

get '/no_title_error' do
  @page_title = 'エラー'

  erb %( <h2>タイトルを入力して下さい</h2> )
end
