### 概要

ブログCSVファイルのアップロードと、アップロードしたブログの一覧表示ができるサイトです。

---

### 環境

- Ruby 3.3.1
- Rails 7.1.3.3
- MySQL 8.0
- Ubuntu 22.04

---

### 環境構築手順

- ruby 3.3.1 のインストール

※操作について、「$」は一般ユーザーを、「#」はrootユーザーを意味します。  

以下を実行します。（これはrbenvを全ユーザーが使えるようにした例です。一般ユーザーで「/home/(ユーザー名)/.rbenv」にcloneしてもいいです。）
```
# apt install -y git build-essential zlib1g-dev libssl-dev libreadline-dev libyaml-dev libcurl4-openssl-dev libffi-dev
# git clone https://github.com/rbenv/rbenv.git /usr/local/rbenv
# git clone https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins/ruby-build
```

visudoを実行し、「Defaults secure_path」の値の末尾に「:/usr/local/rbenv/bin:/usr/local/rbenv/shims」を追加します。

/etc/profileを開き、以下を追加します。
```
export RBENV_ROOT=/usr/local/rbenv
export PATH="$RBENV_ROOT/bin:$PATH" 
eval "$(rbenv init -)"
```

以下を実行します。
```
# rbenv install 3.3.1
# rbenv rehash
```

- MySQL 8.0 のインストール

```
# apt install -y mysql-server-8.0 install libmysqlclient-dev
```

mysqlを起動し、一般ユーザーを追加します。（hoge, fooは適宜読み替えてください。）
```
# mysql
mysql> create user 'hoge'@'localhost' identified by 'foo';
mysql> grant all on *.* to 'hoge'@'localhost' with grant option;
mysql> flush privileges;
```

- ソースコードのチェックアウト

※以下の手順は「~/blog_import_sample」ディレクトリにクローンしたものとして進めます。環境に応じて適宜読み替えてください。
```
$ git clone git@github.com:shirait/blog_import_sample.git
```

- bundle install
```
$ cd ~/blog_import_sample
$ bundle install
```

- DBの用意

以下実行します。
```
$ cp config/database.yml.sample config/database.yml
```

「config/database.yml」のusernameとpasswordを先ほど作成したMySQLのユーザーのもの（hoge/foo）に書き換えます。


DBを作成し、マイグレーションを行います。
```
$ bin/rake db:create
$ bin/rake db:migrate
```

- サーバー起動
  
```
$ bin/rails s -b 0.0.0.0
```

---

### アプリケーションの使い方

ブラウザを開き、アドレスバーに以下を入力してEnterを押します。
```
http://(サーバのIPアドレス):3000/
```

「csv取込画面」が表示されるので、「参照」をクリックし、csvファイルを選択します。  
続いて「アップロード」を押下し、アップロードを実行します。

登録が正常に終了したら「csvを登録しました。」と表示されるので、「ブログ一覧画面へ」をクリックします。

「ブログ一覧画面」最上部のカテゴリー検索では、セレクトボックスにカテゴリ名と記事の件数を表示しています。  
カテゴリーを選択し、「検索条件とソート条件を適用する」をクリックで検索が行えます。タグは複数選択可能です。  
ソート条件を変更したい場合は「ソート条件」のセレクトボックスを変更してください。

ブログ一覧画面は20件区切りの無限スクロールとなっており、画面を下にスクロールすると次の20件が表示されます。

データを削除したい場合は「データをすべて削除する」をクリックしてください。  
~（なお、このリンクはdevelopment環境の場合のみ表示されます。）~ 

---

### テーブル設計について

テーブル設計は以下としました。
<img width="1028" alt="er" src="https://github.com/shirait/blog_import_sample/assets/16542239/601eb8b9-8317-4b75-b6be-71ada5c0142e">

- ファイルアップロードのような機能はユーザーからの問い合わせが多いと思うので、「ブログ取込履歴」で過去の取込結果を保存するようにしました。
- カテゴリーは（第一正規形を守るため）blogsテーブルとは別に保存しました。ただ、保存の性能だけを考えれば、json型でblogsテーブルのカラムとして保存した方が良いかもしれません。性能の比較は次の課題としたいです。
- blogsテーブルのタイトルは重複不可としました。

---

### その他

- 再度同じcsvをアップロードした場合、ブログのタイトルは重複不可のため、エラーになります。

- CSV内に1件でも登録エラーのブログがあれば、登録を中止します。（「ブログ」、「カテゴリー」、「ブログとカテゴリーの関連」の登録はロールバックされ、「ブログ取込履歴」だけが保存されます。）

- エラーメッセージは最初の10件だけ表示します。

- 違うcsvをアップロードするには、ブログのタイトルが「既存データと重複しない」かつ「csvファイル内で重複しない」必要があります。
