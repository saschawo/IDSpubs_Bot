# IDSpubs_Bot
A fediverse bot that toots publications by the Leibniz Institute for the German Language (IDS)

You will need a Fediverse token to use this. I've created a cronjob on a RaspberryPi to run every 2 hours.

As you can see, the bot accesses pub.ids-mannheim.de, parses all author pages there and looks for new entries. Only entries with a year are tooted, only entries from 2023 onwards are tooted.
