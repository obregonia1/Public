# メモアプリ
シンプルな機能のメモアプリです。

# How to start

1.ローカルの使用するディレクトリにクローンしてください。

`$ git clone https://github.com/obregonia1/Public.git`

2.gemのインストールをして下さい。

`$ bundle install --path vendor/bundle`

3.アプリを起動して下さい。

`$ bundle exec ruby memo.rb`

4.使用するブラウザで以下にアクセスするとメモアプリのトップに移動します。

`http://localhost:4567`

# 仕様
- メモを保存すると`/memos`ディレクトリを作成し、その中に`jsonファイル`で保存します。
- メモのタイトルは必須です。
