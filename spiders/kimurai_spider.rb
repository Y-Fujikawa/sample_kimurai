# frozen_string_literal: true

# https://qiita.com/hibiheion/items/502b1a4091d54d05fb53 を参考に試す
# Kimurai::Baseを継承する
class KimuraiSpider < ApplicationSpider
  # 名前
  @name = 'kimurai_spider'
  # スクレイピングに使用するドライバ
  @engine = :selenium_chrome
  # 最初に訪れるURL。配列で複数設定することも可能。
  @start_urls = ['https://cyclemarket.jp']

  # starts_urlsのページを解析する
  # 継承しているKimurai::Baseのcrawl!メソッドから呼ばれる
  # @param [Nokogiri::HTML::Document] response 対象ページを対象としたNokogiri::HTML.parseの結果
  # @param [String] url 対象ページのURL
  # @param [Hash] data 前ページからの引数
  def parse(response, url:, data: {})
    # CSSセレクタを使ってヘッダのナビゲーションを取得する
    # 項目の取得には「css」や「xpath」といったNokogiriの検索系メソッドが使用できる
    response.css('#nav-global ul li a').each do |menu|
      # HTMLのクラスを見てカテゴリページ以外は除外する
      # ノードのアクセスでもNokogiriと同じメソッドを使用できる
      next if menu[:class].include?('outlet') || menu[:class].include?('parts')

      # ナビゲーションからカテゴリページの情報を取得する
      category_name = menu.css('.caption').text
      category_url = absolute_url(menu[:href], base: url)

      # 「request_to」メソッドでカテゴリページに移動し、カテゴリページを解析する。引数は下記の通り。
      # ・第1引数は移動先のページの解析に使うメソッド
      # ・キーワード引数の「url」は移動先のページのURL
      # ・キーワード引数の「data」は移動先のページの解析に使うメソッドへの引数
      request_to :parse_category_page, url: category_url, data: { category_name: category_name }
    end
  end

  # カテゴリページを解析する
  # @param [Nokogiri::HTML::Document] response 対象ページを対象としたNokogiri::HTML.parseの結果
  # @param [String] url 対象ページのURL
  # @param [Hash] data 前ページからの引数
  def parse_category_page(response, url:, data: {})
    # 商品情報を取得する
    response.css('#cy-products .cy-product-list .product a').each do |product|
      # CSV出力のために1件ごとにハッシュに入れる
      row = {}
      row[:name] = product_name(product.css('.body .title').text.strip)
      row[:category_name] = data[:category_name]
      row[:min_price] = product.css('.min-price').text.strip.delete('^0-9')
      row[:max_price] = product.css('.max-price').text.strip.delete('^0-9')

      # CSVファイルに出力する
      save_to './outputs/kimurai_spider_results.csv', row, format: :csv
    end
  end

  private

  # 商品名にメーカー名がついている場合はメーカー名を取り除く
  # @param [String] base_name 元の商品名
  # @return [String] メーカー名を取り除いた商品名
  def product_name(base_name)
    base_name.include?("\n") ? base_name.split("\n")[1].strip : base_name
  end
end
