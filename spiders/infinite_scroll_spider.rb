# frozen_string_literal: true

require 'kimurai'

class InfiniteScrollSpider < ApplicationSpider
  @name = 'infinite_scroll_spider'
  @engine = :selenium_chrome
  @start_urls = ['https://infinite-scroll.com/demo/full-page/']

  def parse(response, url:, data: {})
    posts_headers_path = '//article/h2'
    count = response.xpath(posts_headers_path).count

    loop do
      browser.execute_script('window.scrollBy(0,10000)') ; sleep 2
      response = browser.current_response

      new_count = response.xpath(posts_headers_path).count
      if count == new_count
        logger.info '> Pagination is done' and break
      else
        count = new_count
        logger.info "> Continue scrolling, current count is #{count}..."
      end
    end

    posts_headers = response.xpath(posts_headers_path).map(&:text)
    logger.info "> All posts from page: #{posts_headers.join('; ')}"
  end
end
