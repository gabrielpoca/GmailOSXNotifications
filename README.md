# Gmail OSX Notificaions

Ruby script that sends osx notifications when you have unread messages in gmail. It watches multiple mailboxes.


## Configuration
First run `bundle`. Then go to the bottom of gmail.rb and replace the upper case words with your information.

## Instalation
Put it somewhere and make it executable: `chmod +x gmail.rb`. Then you can make it run every 10 mintues (example):

	crontab -e

and insert this

	*/10 * * * * /path/to/command