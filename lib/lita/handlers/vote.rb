module Lita
  module Handlers
    class Vote < Handler

      config :db_address, type: String, default: '127.0.0.1:27017'
      
      def initialize(robot)
        super
        
        @db = Mongo::Client.new([ config.db_address ], :database => 'votes')
        @collection = @db[:polls]
      end

      route(/^test/i, command: true, help: {
              'tally' => "Let's the user get the results of the current vote. Usage: /tally"
            }) do |response|
        log.info(response.message.inspect)
        log.info(response.user.inspect)
        log.info(response.room.inspect)
        
        after(10) { |timer| 
          response.reply("Timer works!!")
        }
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
              'vote' => "Let's the user vote on a poll question!. Usage: /vote yes"
            }) do |response|

        info = response.matches[0][0].split(' ')

        poll_id = info[0]
        user_choice = info[1]

        handle_vote(user_choice, response, poll_id)
      end

      route(/^tally\s+(.+)/i, command: true, help: {
              'tally' => "Let's the user get the results of the current vote. Usage: /tally"
            }) do |response|

        @collection.find({:poll_id => response.matches[0][0].to_i, :room => response.room.id}).each do |vote|

          reply = ''
            response.reply(vote)
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
              'tally' => "Let's the user get the results of the current vote. Usage: /tally"
            }) do |response|

        votes = load_polls(response)
        reply = ''

        votes.each do |vote|
          log.info(vote)
          reply << "ID: " << vote['poll_id'].to_s << ' - '
          reply << "\"" << vote['question'] << "\" || "
          reply << 'Called by: ' << vote['initiator'] << ' || '
          reply << 'Options: ' << vote['choices'].to_s
        end

        response.reply(reply)
      end

      route(/^endpoll\s+(.+)/i, command: true, help: {
              'endpoll' => "Let's the user kill the current poll!. Usage: /endpoll"
            }) do |response|

        @collection.delete_one({:poll_id => response.matches[0][0].to_i, :room => response.room.id, :initiator => response.user.name})

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

        @collection.find({:poll_id => poll_id.to_i, :room => response.room.id}).each do |poll|

          if poll['choices'].include?(user_choice)
            if poll['voters'][user_choice].include?(response.user.name)
              response.reply("You've already voted!")
            else
              poll['voters'][user_choice] << response.user.name
              poll['update_at'] = Time.now
              @collection.update_one({:poll_id => poll_id.to_i, :room => response.room.id}, {'$set' => {:voters => poll['voters']}})
              response.reply('Counted!')
            end
          else
            response.reply('Invalid voting option: ' + user_choice)
          end

        end
      end

      def load_polls(response)
        polls = []

        @collection.find({room: response.room.id}).each do |document|
          polls.push(document)
        end

        polls
      end

      Lita.register_handler(self)
    end
  end
end
