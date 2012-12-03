#!/usr/bin/ruby

###################################################################################################
##
## 	This is an awesome script for GMail notifications in OSX.
##  My name is Gabriel Poça. More about me:
## 		http://gabrielpoca.com
## 		http://github.com/gabrielpoca
## 		@gabrielgpoca
##
###################################################################################################
##
## 	HOW TO USE IT
## 		1. 	Configuration is straightforward, just go the bottom of the file.
## 		2. 	Put it crontab. Something like
## 				*/15 * * * * /path/to/this/file > /dev/null 2>&1
## 		3. 	To add a new mailbox or reset just remove the session_file.
## 			The name is in the bottom of the script
##
###################################################################################################
##
## 	LIMITATIONS
## 		1. 	It supports more than two mailboxs, just swap the comments in the lines
##
##					# TerminalNotifier.notify(@text, title: 'Mail Notification', open: 'http://gmail.com') unless self.empty?
##					TerminalNotifier.notify(@text, title: 'Mail Notification', open: 'http://gmail.com', group: 'gmail.rb') unless self.empty?
##
## 					and
##
##    				counts[mailbox] = @gmail.mailbox(mailbox).find(:unread).count
##					# counts[mailbox] = box.count
##
##  		The problem is that with more than two mailboxs you get multple notifications
## 			instead of a replace notification when there is more mail.
##
## 		2. The notification icon can't be changed :(
##
###################################################################################################

require 'gmail'
require 'yaml'
require 'terminal-notifier'

class Message
	attr_reader :text, :instance_id
	def initialize
		@text = ""
	end
	def append(count, place)
		@text << "You have #{count} new messages in #{place}\n" unless count == 0 || place.nil?
	end
	def reset
		@text = ""
	end
	def empty?
		text.eql?("") ? true : false
	end
	def notify
		# Use the first to have more than 2 mailboxs
		# TerminalNotifier.notify(@text, title: 'Mail Notification', open: 'http://gmail.com') unless self.empty?
		TerminalNotifier.notify(@text, title: 'Mail Notification', open: 'http://gmail.com', group: 'gmail.rb') unless self.empty?
	end
end

class Session
	attr_reader :gmail, :file, :session, :mailboxs

	def initialize(gmail, file, mailboxs)
		@gmail = gmail
		@file = file
		@mailboxs = mailboxs
		if File.exists?(@file)
			@session = YAML.load_file @file
		else
			@session = self.get_session_hash
		end
	end

	def update_file
		session = self.get_session_hash
		File.open(@file, File::WRONLY|File::CREAT) do |f|
			f.write(session.to_yaml)
		end
	end

	def get_count_by_mailbox
		counts = Hash.new
		@mailboxs.each do |mailbox|
			box = @gmail.mailbox(mailbox).find(:unread, {:query => ['UID', ((@session[mailbox]+1)..-1)]})
			unless box.empty? || box.last.uid == @session[mailbox]
				counts[mailbox] = @gmail.mailbox(mailbox).find(:unread).count
				# counts[mailbox] = box.count
			end
		end
		counts
	end

	def get_session_hash
		session = Hash.new
		@mailboxs.each do |mailbox|
			session[mailbox] = Integer(@gmail.mailbox(mailbox).find(:all, {:query => ['UID', (1..-1)]}).last.uid)
		end
		session
	end
end

# read custom variables from end of file
@accounts = YAML.load(DATA)

# get session file
@session_file = ENV['HOME']+"/"+@accounts["session_file"]

# establish connection to gmail
@gmail = Gmail.connect @accounts["username"], @accounts["password"]

# read mailboxs
@mailboxs = @accounts['mailboxs'].split(',')

# crate session and get new message count by mailbox
@session = Session.new @gmail, @session_file, @mailboxs
@count_by_mailbox = @session.get_count_by_mailbox

# create message to notify
@count_by_mailbox.delete_if{|name, count| count == 0}.each_slice(2) do |slice|
	@message = Message.new
	slice.each { |name, count| @message.append count, name if count > 0 }
	@message.notify
end

# update the session file
@session.update_file

__END__
username: YOUR EMAIL
password: YOUR PASSWORD
mailboxs: Inbox,OTHER MAILBOX
session_file: .gmailscript.session.yaml