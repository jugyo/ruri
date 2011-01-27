# coding: utf-8
require 'spec_helper'

describe Ruri::Search do
  describe '.search' do
    it {
      mock(Ruri::Search).open("#{Ruri::Search::BASE_URL}/ja/search/version:1.8.7/query:gsub%21/") { '<html></html>' }
      mock(Ruri::Search).parse_search_result('<html></html>') { [Ruri::Search::Result.new('title', 'http://foo', 'foo...')] }
      Ruri::Search.search('gsub!', :version => '1.8.7').should == [Ruri::Search::Result.new('title', 'http://foo', 'foo...')]
      Ruri::Search.last_result.should == []
      Ruri::Search.last_query.should == nil
    }

    describe ':memory => true' do
      it {
        mock(Ruri::Search).open("#{Ruri::Search::BASE_URL}/ja/search/version:#{Ruri::Search::DEFAULT_VERSION}/query:gsub%21/") { '<html></html>' }
        mock(Ruri::Search).parse_search_result('<html></html>') { [Ruri::Search::Result.new('title', 'http://foo', 'foo...')] }
        result = Ruri::Search.search('gsub!', :memory => true)
        result.should == [Ruri::Search::Result.new('title', 'http://foo', 'foo...')]
        Ruri::Search.last_result.should == result
        Ruri::Search.last_query.should == 'gsub!'
      }
    end
  end

  describe '.parse_search_result' do
    it {
      result = Ruri::Search.parse_search_result(File.read(File.join(fixture_path, 'search_result.html')))
      entry = result.first
      entry.title.should == "String#gsub(pattern, replace) -> String"
      entry.url.should == "#{Ruri::Search::BASE_URL}/ja/1.9.2/method/String/i/gsub.html"
      entry.summary.should == "文字列中で pattern にマッチする部分全てを\n文字列 replace で置き換えた文字列を生成し返します。"
    }
  end

  describe '.open_reference' do
    pending
  end

  describe '.parse_reference' do
    pending
  end
end
