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

def basearch(name)
  searchstring = URI.encode_www_form_component(name, enc=nil)
  agent = Mechanize.new
  agent.redirect_ok = false
  search_link = "https://www.beeradvocate.com/search/?q=#{searchstring}"
  ba_search_results = agent.get(search_link)
  status_code = ba_search_results.code
  if ba_search_results.code[/30[12]/]
    return "https://www.beeradvocate.com/#{ba_search_results.header['location']}"
  end
  doc = Nokogiri::HTML.parse(ba_search_results.body)
  details_link = doc.search(%q!#ba-content > div:nth-child(3) > div:nth-child(1) > a!).first["href"].strip()
  return details_link ? "https://www.beeradvocate.com/#{details_link}" : nil
rescue NoMethodError
  return nil
end

def remove_stop_words(name)
  name = name.gsub(/(Co\.|Company|Brrwery|Brewing)/, "")
  print name
  name
end

def barating_for(name)
  link = basearch(remove_stop_words(name))
  if link
    agent = Mechanize.new
    ba_profile = agent.get(link)
    doc = Nokogiri::HTML.parse(ba_profile.body)
    {:overall => doc.search('#score_box > div > span:nth-child(3)').first.inner_text.strip(),
     :avg => doc.search('#info_box > div:nth-child(3) > dl > dd:nth-child(12) > b > span').first.inner_text.strip(),
     :ratings => doc.search('#info_box > div:nth-child(3) > dl > dd:nth-child(16) > span > b').first.inner_text.strip(),
     :brewery => doc.search(%q!#info_box > div:nth-child(3) > dl > dd:nth-child(2) > a > b!).first.inner_text.strip(),
     :style => doc.search(%q!#info_box > div:nth-child(3) > dl > dd:nth-child(6) > a:nth-child(1) > b!).first.inner_text.strip(),
     :abv => doc.search(%q!#info_box > div:nth-child(3) > dl > dd:nth-child(8) > span > b!).first.inner_text.strip().gsub(/[^0-9.]/, ''),
     :title => ba_profile.title.split("-")[0].split(" | ")[0].strip(),
     :photo => "#{doc.search(%q!#main_pic_norm > div > img/@src!).first.inner_text.strip()}",
     :link => link}
  else
    return nil
  end
end  

puts barating_for ARGV[0]