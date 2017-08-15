require 'rails_helper'

RSpec.describe Article, type: :model do
  #pending "add some examples to (or delete) #{__FILE__}"
  describe "#テスト実行" do
    context "ArticleのFactoryを作成した場合" do
      it "テストデータが作成される" do 
        article_model = FactoryGirl.create(:article, text: "hogehoge")
        ### テストが面にテストデータを表示する
        p article_model
      end
    end
  end
end
