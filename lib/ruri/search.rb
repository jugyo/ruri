require 'nokogiri'
require 'open-uri'
require 'erb'
require 'tempfile'

module Ruri
  class Search
    Result = Struct.new(:title, :url, :summary)

    BASE_URL = "http://doc.ruby-lang.org"
    SEARCH_URL = "#{BASE_URL}/ja/search/version:%s/query:%s/"
    DEFAULT_VERSION = '1.9.2'

    class << self
      attr_accessor :last_result, :last_query

      def last_result
        @last_result ||= []
      end

      def web_page_cache
        @web_page_cache ||= {}
      end

      def open(uri)
        puts "\e[34m=> #{uri}\e[0m"
        if web_page_cache.key?(uri)
          web_page_cache[uri]
        else
          web_page_cache[uri] = Kernel.open(uri).read
        end
      end

      def search(query, options = {})
        options = {:version => DEFAULT_VERSION, :memory => false}.merge(options)
        url = SEARCH_URL % [options[:version], ERB::Util.url_encode(query)]
        content = open(url)
        result = parse_search_result(content)
        if options[:memory]
          self.last_query = query
          self.last_result = result
        end
        result
      end

      def parse_search_result(html)
        result = []
        doc = Nokogiri::HTML(html)
        doc.css('.entries').each do |dl|
          [
            dl.css('.entry-name .signature'),
            dl.css('.entry-document .entry-link a'),
            dl.css('.entry-summary')
          ].transpose.each do |name, link, summary|
            result << Result.new(name.content.strip, BASE_URL + link[:href], summary.content.strip)
          end
        end
        result
      end

      def open_reference(result)
        return nil unless result
        parse_reference(open(result.url))
      end

      def parse_reference(html)
        doc = Nokogiri::HTML(html)
        doc.css('title').remove
        first_p = doc.css('p').first
        first_p.content = "\e[34m#{first_p.content.gsub("\n", " ").strip}\e[0m\n"
        doc.css('h1').each {|e| e.content = "#{e.content.strip}\n#{'=' * 80}\n"}
        doc.css('h2').each {|e| e.content = "#{e.content.strip}\n#{'-' * 80}\n"}
        doc.css('h3').each {|e| e.content = "### #{e.content.strip}\n"}
        doc.css('h4').each {|e| e.content = "#### #{e.content.strip}\n"}
        doc.css('dt.method-heading').each {|e| e.content = "\e[36m#{e.content.strip}\e[0m\n"}
        doc.css('dd').each {|e| e.content = "\n    #{e.content.strip.gsub("\n", "\n    ")}\n"}
        doc.css('pre').each {|e| e.content = "\n#{e.content.strip}\n"}
        doc.content.gsub(/\n[\n\s]*\n/, "\n\n").strip
      end
    end
  end
end

command 'search', <<HELP do |query|
Search the Ruby reference manual
HELP
  Ruri::Util.less do |file|
    file << <<-HELP
\e[41m You can open a individual reference as following > open 0 \e[0m

    HELP
    Ruri::Search.search(query, :memory => true).each_with_index do |result, index|
      file << <<-RESULT
#{index} \e[42m#{result.title}\e[0m
  \e[34m#{result.url}\e[0m
    #{result.summary.gsub("\n", "\n    ")}

      RESULT
    end
  end
end

command 'open', <<HELP do |index|
Open the specified reference
HELP
  if ref = Ruri::Search.open_reference(Ruri::Search.last_result[index.to_i])
    Ruri::Util.less(ref)
  else
    puts "\e[31mNot found :(\e[0m"
  end
end

command 'go', <<HELP do |query|
Go to the page
HELP
  if ref = Ruri::Search.open_reference(Ruri::Search.search(query).first)
    Ruri::Util.less(ref)
  else
    puts "\e[31mNot found :(\e[0m"
  end
end
