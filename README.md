# 概要

* 1アクションで2つのモデルを同時に保存する練習
    * 記事作成時にarticleモデルに記事を保存する
    * 同時に、コメンテーターとそのコメントもcommentモデルに保存する

# 変更内容

## モデルの修正

```
### app/models/comment.rb
================================================
class Comment < ApplicationRecord
  belongs_to :article
end
================================================

### app/models/article.rb
================================================
class Article < ApplicationRecord
  #has_many :comments   ### has_oneに変更
  has_one :comment      ### 単数形にする
  validates :title, presence: true, length: { minimum: 5 }
end
================================================
```

### 参考

* [has_one と belongs_to についての復習](http://qiita.com/color_box/items/2147461a64d6b9e583c9)

## コントローラの修正(newとcreate)

```
class ArticlesController < ApplicationController
  def new
    @article = Article.new
    @comment = Comment.new
  end

  def create
    @article = Article.new(article_params)
    @comment = Comment.new(comment_params)

    Article.transaction do
      @comment.article = @article
      @article.save
      @comment.save
      flash[:notice] = "記事を投稿しました。"
      redirect_to @article
    end
  end
...
  private

  def article_params
    params.require(:article).permit(:title, :text)
  end

  def comment_params
    params.require(:comment).permit(:commenter, :body)
  end
  
```

* new
    * @articleと@commentにビューで値を入力するための箱を作る
* create
    * @articleと@commentにビューで入力された値が入る

### article_paramsのデバッグ実行例

```ruby
0> params.require(:article)
=> <ActionController::Parameters {"title"=>"tttttt", "text"=>"sss"} permitted: false>

0> params.require(:article).permit(:title)
Unpermitted parameter: :text
=> <ActionController::Parameters {"title"=>"tttttt"} permitted: true>

0> params.require(:article).permit(:text)
Unpermitted parameter: :title
=> <ActionController::Parameters {"text"=>"sss"} permitted: true>

0> params.require(:article).permit(:title, :text)
=> <ActionController::Parameters {"title"=>"tttttt", "text"=>"sss"} permitted: true>

### comment_paramsの例
0> params.require(:comment)
=> <ActionController::Parameters {"commenter"=>"bbb", "body"=>"ddd"} permitted: false>
```

### `@comment.article = @article` について

```ruby
### @articleを代入する前はnil
0> @comment.article
=> nil

0> @comment
=> #<Comment id: nil, commenter: "commentコメンター", body: "commentボディー", article_id: nil, created_at: nil, updated_at: nil>

0> @article
=> #<Article id: nil, title: "articleタイトル", text: "articleテスト", created_at: nil, updated_at: nil, image: nil>

0> @comment.article = @article
=> #<Article id: nil, title: "articleタイトル", text: "articleテスト", created_at: nil, updated_at: nil, image: nil>

0> @comment
=> #<Comment id: nil, commenter: "commentコメンター", body: "commentボディー", article_id: nil, created_at: nil, updated_at: nil>

### 代入すると@comment.articleが使えるようになる
0> @comment.article
=> #<Article id: nil, title: "articleタイトル", text: "articleテスト", created_at: nil, updated_at: nil, image: nil>

```

```
### commentsDBのarticle_idに記事のIDが入る
mysql> select * from articles;
+----+---------------------+------------------------------------+---------------------+---------------------+-------+
| id | title               | text                               | created_at          | updated_at          | image |
+----+---------------------+------------------------------------+---------------------+---------------------+-------+
|  6 | articleタイトル     | articleテスト                      | 2017-08-18 00:07:15 | 2017-08-18 00:07:15 | NULL  |
+----+---------------------+------------------------------------+---------------------+---------------------+-------+

mysql> select * from comments;
+----+------------------------+--------------------------+------------+---------------------+---------------------+
| id | commenter              | body                     | article_id | created_at          | updated_at          |
+----+------------------------+--------------------------+------------+---------------------+---------------------+
|  7 | commentコメンター      | commentボディー          |          6 | 2017-08-18 00:07:15 | 2017-08-18 00:07:15 |
+----+------------------------+--------------------------+------------+---------------------+---------------------+
```

* `@comment.article = @article` をコメントアウトした場合
    * @articleのみ保存されて@commentは保存されない
    
```
0> @comment.save
=> false
```

### transactionは`save!`とする理由

* 失敗すると例外をスローする
    * つけてない場合、片方が成功で片方が失敗したら成功した方のみモデルが保存される

## ビューの修正

### 

```
### app/views/articles/new.html.erb
================================================
<h1>New Article</h1>

<%= render 'form' %>

<%= link_to 'Back', articles_path %>
================================================

### app/views/articles/_form.html.erb
================================================
<%= form_for @article do |f| %>
    <% if @article.errors.any? %>
        <div id="error_explanation">
          <h2><%= pluralize(@article.errors.count, "error") %> prohibited
            this article from being saved:</h2>
          <ul>
            <% @article.errors.full_messages.each do |msg| %>
                <li><%= msg %></li>
            <% end %>
          </ul>
        </div>
    <% end %>
    <p>
      <%= f.label :title %><br>
      <%= f.text_field :title %>
    </p>

    <p>
      <%= f.label :text %><br>
      <%= f.text_area :text %>
    </p>

    <%= fields_for @comment do |f2|  %>
        <p>
        <%= f2.label :commenter %><br>
        <%= f2.text_field :commenter %><br>
        </p>

        <p>
        <%= f2.label :body %><br>
        <%= f2.text_field :body %><br>
        </p>
    <% end %>

    <p>
      <%= f.submit %>
    </p>
<% end %>
================================================
```

* form_for
    * モデルの新規インスタンスに値を追加して保存したい時に使用するヘルパーメソッド
        * フォームが簡単に作成できる
        * 入力されたデータをテーブルに保存できる
    * 特徴
        * モデルのインスタンスを引数に持つ
            * ここでは`@article`
        * インスタンスの状態によって振り分けるアクションが自動的に変わる
            * インスタンスに何も情報が入っていない場合はcreateアクションに振り分けられる
            * インスタンスに情報が入っていればupdateアクションに振り分けられる
            * 自動的に振り分けられない場合の指定の仕方
                * create : `form_for @article, url: articles_path`
                * update : `form_for @article, url: article_path(@article), html: {method: "patch"}`
        * submitボタンを押した時の挙動
            * フォームに入力された値がインスタンスにそれぞれの属性値としてセットされる
            * 対応するテーブルのカラムに保存される
* fields_for
    * モデルを固定してフォームを生成する
        * form_for内で異なるモデルを編集できるようになる
* 【参考】form_tag
    * モデルに基づかないフォームを作るときに使う
        * 検索窓など


### 参考
* [【Rails】form_forの使い方](http://qiita.com/JumpeiYoshimura/items/ee5af466ef7959567174)
* [【Rails】form_for/form_tagの違い・使い分けをまとめた](http://qiita.com/shunsuke227ono/items/7accec12eef6d89b0aa9)


## showアクションの修正

```
### app/controllers/articles_controller.rb
================================================
  def show
    @article = Article.find(params[:id])
    
    ### has_oneを使わない場合。articleのidでcommentモデルを検索する
    #@comment = Comment.find_by(article_id: params[:id])

    ### has_oneを使う場合は以下で検索できる
    ### (対象のarticleのidでcommentのarticle_idを検索してくれる
    @comment = @article.comment
  end
================================================

```



