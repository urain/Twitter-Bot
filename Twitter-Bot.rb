require 'chatterbot/dsl'
require 'time'


$hashtag_to_search	= "#ArcheAge"
$text_to_add		= " bit.ly/1tYRTV4 #ArcheAge"

$tStart 			= Time.now
# Default rate limit is 2400 tweets in a day = 1 every 32..42 secs
$tweets_delay 		= 14400 # Once every 4 hours
$tweetsStart		= $tStart
$tweets 			= Array.new
$rtweets 			= Array.new
$tweets_cpy			= $tweets.dup
$rtweets_cpy		= $rtweets.dup
$tweets_str			= ""
$rtweets_str		= ""

$oldArrayLen		= 0 
$curArrayLen		= 0
$arrayLoc 			= 0

$failures 			= 0 
$failures_time_last = 0.0
$failures_time	    = 0.0
$failures_mins  	= 0.0
$failed_at_tweet	= 0 
$failures_tweet_cnt = 0

$totalTweets 		= 0

def clean_tweet_string(string)
	temp = string
	#add random alpha numeric to front of string
	temp = rand(36).to_s(36) + " " + temp
	#remove users
	temp.gsub!(/@[\w\d]{1,100}\s/, '')
	#remove hashtags
	temp.gsub!(/#[\w\d]{1,100}\s/, '')
	#remove urls
	temp.gsub!(/(http|ftp|https|t\.co|bit\.ly)[\S]{1,100}\s/, '')
	#add the hashtag you want
	temp = temp + " " + $text_to_add
	return temp
end	

def array_clean_shuffle(array)
	temp = array
	#clean each element of the table
	temp.map!{|x| clean_tweet_string(x)}
	#shuffle the array randomly
	temp.shuffle!
	return temp
end

def update_tweets
	File.open('tweets.txt', 'a+') do |f|
		# If tweets.txt is empty, reset since_id
		if File.zero?("tweets.txt")
			since_id(0)
		end
		# if populated, update tweets.txt from since_id in config file
		search($hashtag_to_search) do |tw|
			f.puts tw[:text]
		end
		update_config

		$oldArrayLen = $curArrayLen

		f.each_line do |line|
			$tweets.push(line)
			#$rtweets.push(tweet[:id])
		end
		$curArrayLen = $tweets.length
		$tweets.shuffle
		$rtweets.shuffle
		$tweets_cpy = $tweets.dup
		$rtweets_cpy = $rtweets.dup

		#close the file
		f.close
		sleep(2)
	end
end

def status()
	puts "Bot Started At:\t\t#{$tStart}"
	puts "Last Start:\t\t#{$tweetsStart}"
	puts "Last Failure:\t\t#{$failures_time}"
	puts "Mins To Failure:\t#{$failures_mins}"
	puts "Tweets To Failure:\t#{$failures_tweet_cnt}"
	puts "Num Total Failures:\t#{$failures}\n\n"

	puts "Tweets Old Table Size:\t#{$oldArrayLen}"
	puts "Tweets New Table Size:\t#{$curArrayLen}"
	puts "Tweets Remaining:\t#{$tweets_cpy.length}"
	puts "Tweets Delay:\t\t#{$tweets_delay} to #{$tweets_delay+10} secs"
	puts "Tweets Per Hour:\t#{(($totalTweets / (Time.now - $tStart)) * 3600).round}"
	puts "Total Tweets:\t\t#{$totalTweets}\n\n"
end

def progress_bar(secs)
	p = secs.to_f / 10
	puts "-" * 10 + "|"
	for i in 0...10 do
		print "*"
		sleep(p)
	end
end


loop do

	$tweetsStart = Time.now
	
	if $tweets_cpy.empty?
		update_tweets
	end

	while $tweets_cpy.empty? == false do	
		begin
			$arrayLoc = rand($tweets_cpy.length)


			$tweets_str = clean_tweet_string($tweets_cpy[$arrayLoc])
			#$rtweets_str = $rtweets_cpy[$arrayLoc]

			#tweet('#ElderScrollsOnline much awesome, such wow! What happened to the fun?? http://bit.ly/1tYRTV4')
			tweet($tweets_str)
			#retweet($rtweets_str)
			$tweets_cpy.delete_at($arrayLoc)
			#$rtweets_cpy.delete_at($arrayLoc)
			#$totalTweets = $totalTweets + 2
			$totalTweets = $totalTweets + 1

			system "clear"
			puts "Modified:\t#{$tweets_str}"
			status
			s = rand(($tweets_delay)..($tweets_delay + 10))
			puts "Next Tweet In: #{s} seconds"
			progress_bar(s)
		rescue => e
			err = e.to_s
			if err.include? "Sorry"			
				$tweets.delete_at($arrayLoc)
				$rtweets.delete_at($arrayLoc)
			end
			if $failed_at_tweet != $totalTweets
				$failures = $failures + 1
				$failures_tweet_cnt = $totalTweets - $failed_at_tweet
				$failed_at_tweet = $totalTweets
				$failures_time_last = $failures_time
				$failures_time = Time.now
				$failures_mins = ($failures_time - $failures_time_last) / 60.0
				$tweets_delay = $tweets_delay + 1
			end	
			system "clear"
			puts "#{err}\n\n"
			status
			puts "ERROR Waiting 300 Seconds"
			progress_bar(300)
			$tweetsStart = Time.now
			next
		end
	end
end
