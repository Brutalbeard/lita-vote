module Lita
  module Handlers
    # Vote handler
    class Vote < Handler
      # insert handler code here

      route(/^poll\s+(.+)/i, command: true, help: {
              'poll' => "Let's the user call a new poll for everyone to vote on. Usage: /poll 'Is Ian an idiot?' - yes or no"
            }) do |response|

        message_body = response.matches[0][0]

        vote = createPoll(message_body, response)

        # save that beauty
        redis.set('current_vote', MultiJson.dump(vote))

        response.reply('Poll created!')
      end

      route(/^vote\s+(.+)/i, command: true, help: {
              'vote' => "Let's the user vote on a poll question!. Usage: /vote yes"
            }) do |response|

        vote = MultiJson.load(redis.get('current_vote'))

        user_choice = response.matches[0][0]

        handleVote(vote, user_choice, response)
      end

      route(/^tally/i, command: true, help: {
              'tally' => "Let's the user get the results of the current vote. Usage: /tally"
            }) do |response|

        vote = MultiJson.load(redis.get('current_vote'))
        reply = ''

        vote['voters'].each do |options|
          reply.concat(options[0] + ": -total- #{options[1].length}\n")
          options[1].each do |voter|
            reply.concat(voter + "\n")
          end
          reply.concat("\n- - - - -\n")
        end

        response.reply(reply)
      end

      route(/^endpoll/i, command: true, help: {
              'endpoll' => "Let's the user kill the current poll!. Usage: /endpoll"
            }) do |response|

        vote = {
          question: '',
          choices: [],
          voters: [],
          initiator: '',
          created_at: '',
          update_at: ''
        }
        redis.set('current_vote', MultiJson.dump(vote))
        response.reply('All gone!')
      end

      def createPoll(message_body, response)
        # the setup...
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
          created_at: Time.now,
          update_at: Time.now
        }

        vote
      end

      def handleVote(vote, user_choice, response)
        if vote['choices'].include?(user_choice)
          if vote['voters'][user_choice].include?(response.user.name)
            response.reply("You've already voted!")
            return
          end
          vote['voters'][user_choice] << response.user.name
          vote['update_at'] = Time.now
          response.reply('Counted!')
        else
          response.reply('Invalid voting option: ' + user_choice)
        end
        redis.set('current_vote', MultiJson.dump(vote))
      end

      Lita.register_handler(self)
    end
  end
end
