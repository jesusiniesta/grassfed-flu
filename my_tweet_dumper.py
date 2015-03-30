#!/usr/bin/env python3
# encoding: utf-8

import tweepy #https://github.com/tweepy/tweepy
import csv
import json
import time, datetime

#Twitter API credentials
consumer_key = ""
consumer_secret = ""
access_key = ""
access_secret = ""

def getTimestamp():
	ts = time.time()
	return datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d-%H-%M-%S')

def geoNoOrigFFS (tweet):
	# 'wtf1'| 'wtf2'| 'wtf3'|  'latitude' 'longitude' | 'username' | 'userid' | 'datetime' | 'msg'
	print('0|0|0|' 
		  + 'TODO')

def get_auth():
	auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
	auth.set_access_token(access_key, access_secret)
	return auth

def getTweetsInSpain (filename, tweets_per_file = 20000):
	''' 
	based on http://stackoverflow.com/questions/26949957/is-there-a-way-for-me-to-download-all-the-tweets-made-by-all-twitter-users-in-a
	'''
	import tweepy

	auth = get_auth()

	class StreamListener(tweepy.StreamListener):
	
		def __init__(self, api=None):
			super(StreamListener, self).__init__()
			self.count = 0
			self.f = open(filename, "w")

		def on_status(self, status):
			print( 'Ran on_status: ' + status.text)

		def on_error(self, status_code):
			print( 'Error: ' + repr(status_code))
			return False

		def on_data(self, data):
			self.count += 1
			self.f.write(data)

			if (self.count % 100 == 1):
				print( 'got tweet #' + str(self.count))
			
			if (self.count >= tweets_per_file):
				self.f.close()
				return False
			else: 
				return True

	# boxes
	spain_west = [-9.62,35.8,0.92,43.9]
	spain_east = [0.915,37.87,4.92,43.13]
	spain      = spain_west + spain_east

	print(spain)

	streamer = tweepy.Stream(auth=auth, listener=StreamListener())
	streamer.filter(locations = spain, async=False)

if __name__ == '__main__':

	while True: 
		nextfile = "tweets"+getTimestamp()+".json"
		print(getTimestamp() + " => NEW FILE : " + nextfile)
		getTweetsInSpain(nextfile, 6000)
