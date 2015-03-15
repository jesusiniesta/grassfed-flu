
setwd("~/proyecto")
source("grassfed-flu/lib.R")

tweets <- ReadTweets('data/tweets5.201308.csv')
users <- Users(tweets)
write.table(users, file="data/users.2013.08", sep="|")

