require 'rubygems'
require 'rest_client'
require 'json'
require 'mechanize'
require 'hpricot'
require 'nokogiri'

def googlesearch(name)
  searchstring = name.gsub(" ", "+")
  response = RestClient.get("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=site:beeradvocate.com+#{searchstring}")
  link = JSON.parse(response.body)['responseData']['results'].slice(0)
  return link ? link['url'] : nil
end

def barating_for(name) 
  link = googlesearch(name)
  if link
    agent = Mechanize.new
    ba_profile = agent.get(link)
    doc = Nokogiri::HTML.parse(ba_profile.body)
    {:overall => doc.search('.BAscore_big').first.inner_text.strip(),
     :bros => doc.search('.BAscore_big').last.inner_text.strip(),
     :brewery => doc.search(%q!//b[text() = "Brewed by:"]/following-sibling::a/child::b!).first.inner_text.strip(),
     :style => doc.search(%q!//b[text() = "Style | ABV"]/following-sibling::a/child::b!).first.inner_text.strip(),
     :abv => doc.search(%q!//b[text() = "Style | ABV"]/following-sibling::a/following-sibling::text()!).first.inner_text.strip().gsub(/[^0-9.]/, ''),
     :title => ba_profile.title.split("-")[0].split(" | ")[0].strip(),
     :photo => "#{doc.search(%q!//img[@height = "300"]/@src!).first.inner_text.strip()}",
     :link => link}
  else
    return nil
  end
end  

puts barating_for ARGV[0]