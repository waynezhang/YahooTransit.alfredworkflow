# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'builder'

USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 5_1 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9B179 Safari/7534.48.3";

def parse_route node
	node.at_css('p.time').content.strip.sub('～', " #{node.at_css('dl dt').content.strip} ")
end

def parse_station node
	node.at_css('dl dt').content.strip
end

def search from, to
	routes = []
	doc = Nokogiri::HTML(open(URI::encode("http://transit.loco.yahoo.co.jp/search/result?flatlon=&from=#{from}&tlatlon=&to=#{to}"), "User-Agent" => USER_AGENT))
	(1..6).each do |route|
		begin
			route = doc.css("div#route#{route}")
			line = ''
			routemap = route.at_css("div.routemap")
			routemap.children.each do |ele|
				case ele.attr('class')
				when 'station' then line += " #{ele.at_css('dt').content.strip}"
				when 'section' then 
					ele.children.each do |child|
						if child.attr('class') == 'station' then
							line += " #{parse_station child}"
						elsif child.attr('class') == 'route' then
							line += " #{parse_route child}"
						end
					end
				when 'route walk' then
					line += " #{parse_route ele}"
				end
			end
		rescue
		else
			from = route.at_css("li.fromtime").content
			to = route.at_css("li.totime").content
			time = route.at_css("li.totaltime").content
			routes << ["#{from} #{to} #{time}", line.strip]
		end
	end
	routes
end

def to_xml routes, link
	xml = Builder::XmlMarkup.new
	xml.instruct!
	xml.items do
		if routes != nil then
			routes.each do |route|
				xml.item(:valid => "yes", :uid => "#{route[0]}", :arg => "#{link}") do
					xml.title "#{route[0]}"
					xml.subtitle "#{route[1]}"
					xml.icon "icon.png"
				end
			end
		end
	end

	xml.target!
end

if ARGV.length == 2 then
	routes = search ARGV[0], ARGV[1]
	xml = to_xml routes, "http://transit.loco.yahoo.co.jp/search/result?from=#{ARGV[0]}&to=#{ARGV[1]}"
	puts xml
end