module Lita
  module Handlers
    class Vote < Handler

      config :mongodb_address, type: String, default: '127.0.0.1:27017'
      config :mongodb_password, type: String, default: ''
      config :mongodb_user, type: String, default: ''
      config :mongodb_database, type: String, default: 'votes'
      
      def initialize(robot)
        super
        
        @db = Mongo::Client.new([ config.mongodb_address ], 
          :database => config.mongodb_database,
          :user => config.mongodb_user,
          :password => config.mongodb_password
          )
        @collection = @db[:polls]
      end

      route(/^poll\s+(.+)/i, command: true, help: {
              'poll' => "Let's the user call a new poll for everyone to vote on. Usage: /poll 'Is Ian an idiot?' - yes or no"
            }) do |response|

        message_body = response.matches[0][0]

        vote = create_poll(message_body, response)

        # save that beauty
        @collection.insert_one(vote)

        response.reply('Poll created!')
      end

      route(/^vote\s+(.+)/i, command: true, help: {
              'vote' => "Let's the user vote on a specific poll question by ID. Usage: /vote 1 yes"
            }) do |response|

        info = response.matches[0][0].split(' ')

        poll_id = info[0]
        user_choice = info[1]

        handle_vote(user_choice, response, poll_id)
      end

      route(/^tally\s+(.+)/i, command: true, help: {
              'tally' => "Let's the user get the results a poll by ID. Usage: /tally 1"
            }) do |response|

        @collection.find({
          poll_id: response.matches[0][0].to_i, 
          room: response.room.id, 
          created_at: {
            '$gte' => Time.at(Time.now.to_i - 86400)
          }
        }).each do |vote|

          reply = ''

            reply.concat("**" << vote['question'] << "**\n\n")


            vote['voters'].each do |options|
              reply.concat(options[0] + ": -total- #{options[1].length}\n")
              options[1].each do |voter|
                reply.concat(voter + "\n")
              end
              reply.concat("\n- - - - -\n")
            end

          response.reply(reply)
        end
      end

      route(/^polls/i, command: true, help: {
              'tally' => "Let's the user get the list of current polls and their options. Usage: /polls"
            }) do |response|

        votes = load_polls(response)
        reply = ''

        if(votes.length == 0)
          reply << 'No current polls'
        end

        votes.each do |vote|
          log.info(vote)
          reply << "ID: " << vote['poll_id'].to_s << ' - '
          reply << "\"" << vote['question'] << "\" || "
          reply << 'Called by: ' << vote['initiator'] << ' || '
          reply << 'Options: ' << vote['choices'].to_s << "\n"
        end

        response.reply(reply)
      end

      route(/^endpoll\s+(.+)/i, command: true, help: {
              'endpoll' => "Let's the user kill the current poll!. Usage: /endpoll"
            }) do |response|

        @collection.delete_one({
          poll_id: response.matches[0][0].to_i, 
          room: response.room.id, 
          initiator: response.user.name, 
          created_at: {
            '$gte' => Time.at(Time.now.to_i - 86400)
          }
        })

        response.reply('All gone!')
      end

      def create_poll(message_body, response)
        # the setup...
        polls = load_polls(response)
        iterator = polls.length > 0? polls.last['poll_id'] + 1: 1

        parts = message_body.split('-')

        poll_question = parts[0]
        voting_opts = parts[1].delete!(' ').split('or')
        voters = {}

        # add a hash to store who voted for what
        voting_opts.each do |option|
          voters[option] = []
        end

        # construct the vote hash
        vote = {
          question: poll_question,
          choices: voting_opts,
          voters: voters,
          initiator: response.user.name,
          room: response.room.id,
          created_at: Time.now,
          update_at: Time.now,
          poll_id: iterator
        }

        vote
      end

      def handle_vote(user_choice, response, poll_id)

        @collection.find({
            poll_id: poll_id.to_i, 
            room: response.room.id, 
            created_at: {
              '$gte' => Time.at(Time.now.to_i - 86400)
            }
          }).each do |poll|

          if poll['choices'].include?(user_choice)
            if poll['voters'][user_choice].include?(response.user.name)
              response.reply("You've already voted!")
            else
              poll['voters'][user_choice] << response.user.name
              poll['update_at'] = Time.now
              @collection.update_one({:poll_id => poll_id.to_i, :room => response.room.id}, {
                '$set' => {
                  :voters => poll['voters'],
                  :updated_at => Time.now
                  }
                })
              response.reply('Counted!')
            end
          else
            response.reply('Invalid voting option: ' + user_choice)
          end

        end
      end

      def load_polls(response)
        polls = []

        @collection.find({
          room: response.room.id,
          created_at: {
              '$gte' => Time.at(Time.now.to_i - 86400)
            },
          }).each do |document|
          polls.push(document)
        end

        polls
      end

      Lita.register_handler(self)
    end
  end
end
