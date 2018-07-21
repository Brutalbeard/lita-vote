# lita-vote

Let's folks take a vote on something! Like what game to play next or whatever.

-VERY NOT DONE- 

Added a Mongo DB so I could track multiple votes at once. 

## Installation

Add lita-vote to your Lita instance's Gemfile:

``` ruby
gem "lita-vote"
```

## Configuration

Very verbose, so you can use whatever service you want. Authenticates with password and user. Collections defaults to 'votes'.

``` ruby
config.handlers.vote.mongodb_address = ""
config.handlers.vote.mongodb_user = ""
config.handlers.vote.mongodb_password = ""
config.handlers.vote.mongodb_database = ""
```

## Usage

Each poll gets creted with a poll id, that increments up. Polls are grouped by chat room. To vote for one, or pull a tally, you have to indicate the poll id. Using ```/polls``` will give a readout of the available polls.

```/poll Is Ian a nerd? - yes or no```
```/polls```
```/vote 1 yes```
```/tally 1```
```/endpoll 1```
