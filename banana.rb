require 'slack-ruby-bot'
require 'nokogiri'
require 'open-uri'

def createLink link
	"https://swift.org" + link.attribute("href").value
end

class BananaBot < SlackRubyBot::Bot

	command 'ping' do |client, data, match|
		client.say(text: 'pong', channel: data.channel)
	end

	command 'snapshot' do |client, data, match|
		doc = Nokogiri(open("https://swift.org/download/#snapshots"))
		rows = doc.xpath('//body').xpath('//table[@id="latest-builds"]/tbody/tr')
		links = rows.xpath("//tr/td/span/a")
		text = createLink(links[10]) + "\n" + createLink(links[12]) + "\n" + createLink(links[14])
		client.say(text: text, channel: data.channel)
	end

end

BananaBot.run
