# frozen_string_literal: true

class GithubSpider < ApplicationSpider
  @name = 'github_spider'
  @engine = :selenium_chrome
  @start_urls = ['https://github.com/search?q=Ruby%20Web%20Scraping']

  def parse(response, url:, data: {})
    response.xpath("//ul[@class='repo-list']/div//h3/a").each do |a|
      request_to :parse_repo_page, url: absolute_url(a[:href], base: url)
    end

    if (next_page = response.at_xpath("//a[@class='next_page']"))
      request_to :parse, url: absolute_url(next_page[:href], base: url)
    end
  end

  def parse_repo_page(response, url:, data: {})
    item = {}

    item[:owner] = response.xpath("//h1//a[@rel='author']").text
    item[:repo_name] = response.xpath("//h1/strong[@itemprop='name']/a").text
    item[:repo_url] = url
    item[:description] = response.xpath("//span[@itemprop='about']").text.squish
    item[:tags] = response.xpath("//div[@id='topics-list-container']/div/a").map { |a| a.text.squish }
    item[:watch_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Watch')]/a[2]").text.squish
    item[:star_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Star')]/a[2]").text.squish
    item[:fork_count] = response.xpath("//ul[@class='pagehead-actions']/li[contains(., 'Fork')]/a[2]").text.squish
    item[:last_commit] = response.xpath("//span[@itemprop='dateModified']/*").text

    save_to './outputs/github_spider_results.json', item, format: :pretty_json
  end
end
