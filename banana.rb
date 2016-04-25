require 'slack-ruby-bot'
require 'nokogiri'
require 'open-uri'
require "json"

def fetchLatestSnapshots
	doc = Nokogiri(open("https://swift.org/download/#snapshots"))
	# FIXME: This is unrealible and will break in future ;D
	rows = doc.xpath('//body').xpath('//table[@id="latest-builds"]/tbody/tr')
	links = rows.xpath("//tr/td/span/a")
	date = rows.xpath('//time')
	
	value = lambda { |link, date| return {:url => "https://swift.org" + link.attribute("href").value, :time => date.attribute("datetime").value } }

	xcode = value.call links[10], date[6]
	ubuntu1510 = value.call links[12], date[7]
	ubuntu1404 = value.call links[14], date[8]

	data = []
	data.push(makeSnapshotHash "Xcode", xcode)
	data.push(makeSnapshotHash "Ubuntu 15.10", ubuntu1510)
	data.push(makeSnapshotHash "Ubuntu 14.04", ubuntu1404)

	name = URI(xcode[:url]).path.split('/')[-2]
	date = Date.parse(xcode[:time])
	{:data => data, :date => date, :name => name }
end

def makeSnapshotHash name, data
	{:title => name, :value => "<#{data[:url]}|Download>", :short => true}
end

class BananaBot < SlackRubyBot::Bot

	command 'ping' do |client, data, match|
		client.say(text: 'pong', channel: data.channel)
	end
 
	command 'good boy' do |client, data, match|
                client.say(text: 'I know I am the best :sunglasses:', channel: data.channel)
        end
 
  	match /(.*)say hi to (?<user>\w*)$/ do |client, data, match|
     		client.say(text: "Hello @#{match[:user]}, hope you\'re doing good today!", channel: data.channel)
   	end

	command 'snapshot' do |client, data, match|
		client.web_client.chat_postMessage(
			channel: data.channel, text: 'Hold on fetching lastest snapshot info...', as_user: true)

		snapshot = fetchLatestSnapshots
		client.web_client.chat_postMessage(
			channel: data.channel,
			as_user: true,
			attachments: [
				{
					"fallback": snapshot[:name],
					"color": "#36a64f",
					"title": "Swift Trunk Snapshots",
					"text": "*Released on #{snapshot[:date]}* `#{snapshot[:name]}`",
					"title_link": "https://swift.org/download/#releases",
					"mrkdwn_in": ["text"],
					"fields": snapshot[:data]
				}
			]
		)
	end

	command 'pulls swiftpm' do |client, data, match| 
		json = JSON.parse(open("https://api.github.com/repos/apple/swift-package-manager/pulls?sort=updated&direction=desc").read)
		count = json.count
		json = json.first(5)
		fields = []
		json.each { |pull|
			fields.push({:title => "#{pull["title"]}", :value => "by #{pull["user"]["login"]}", :short => false})
		}

		client.web_client.chat_postMessage(
			channel: data.channel,
			as_user: true,
			attachments: [
				{
					"fallback": "swiftpm PR stats",
					"color": "#36a64f",
					"title": "#{count} pull requests open on swiftpm",
					"title_link": "https://github.com/apple/swift-package-manager/pulls",
					"text": "Showing top #{json.count >= 5 ? 5 : json.count}",
					"fields": fields
				}
			]
		)
	end
end

BananaBot.run
