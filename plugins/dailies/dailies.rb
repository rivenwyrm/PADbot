# Daily dungeon commands: dailies, when, settopic
# Based off the Asterbot mk.1 module by nfogravity

require 'open-uri'
require 'nokogiri'

class DailiesPlugin < PazudoraPluginBase
  def self.helpstring
"!pad dailies [group] [timezone]: displays data on current urgent dungeons"
  end

  def self.aliases
    ['dailies', 'urgents']
  end

  # FUCK TZINFO
  def get_timezone(arg)
    if arg.to_i != 0
      arg.to_i
    elsif arg.downcase == "pacific" || arg.downcase == "pst"
      -7
    elsif arg.downcase == "mountain" || arg.downcase == "mst"
      -6
    elsif arg.downcase == "central" || arg.downcase == "cst"
      -5
    elsif arg.downcase == "eastern" || arg.downcase == "est"
      -4
    elsif arg.downcase == "japan" || arg.downcase == "jst"
      9
    else
      raise "#{arg} is not a recognizable timezone"
    end
  end

  def respond(m, args)
    args = "" unless args
    argv = args.split
    group = nil
    timezone = -7
    if argv.length == 2
      group = argv.first.upcase
      begin
        timezone = get_timezone(argv.last)
      rescue Exception => e
        m.reply e.message
        return
      end
    elsif argv.length == 1 && ["A", "B", "C", "D", "E"].include?(argv.first.upcase)
      group = argv.first.upcase
    elsif argv.length == 1
      begin
        timezone = get_timezone(argv.first)
      rescue Exception => e
        m.reply e.message
        return
      end
    end 

    group ? group_schedule(m, group, timezone) : full_schedule(m, timezone)
  end

  def full_schedule(m, timezone)
    w = WikiaDailies.new
    reward = w.dungeon_reward
    groups = w.get_dailies(timezone)
    rv = groups.each_with_index.map {|times, i| "#{(i + 65).chr}: #{times.join(' ')}"}
    rv = rv.join(" | ")
    m.reply "#{w.today} (UTC #{timezone}) Urgents: #{reward}"
    m.reply rv
    specials = w.specials
    if specials.count > 0
      m.reply "Special dungeon(s): #{specials.join(', ')}"
    end
  end

  def group_schedule(m, group, timezone)
    w = WikiaDailies.new
    reward = w.dungeon_reward.split(", ") #lmao
    index = {"A" => 0, "B" => 1, "C" => 2, "D" => 3, "E" => 4}[group]
    groups = w.get_dailies(timezone)[index]
    rv = ["#{w.today} (UTC #{timezone}) Urgents (#{group}): "]
    reward.length.times do |n|
      rv << "#{reward[n]} @ #{groups[n]}"
    end
    m.reply rv[0] + rv[1..-1].join(', ')
  end
end

=begin

class TomorrowPlugin < PazudoraPluginBase
  def self.helpstring
    "!pad tomorrow: exactly like !pad dailies except it's for...tomorrow!"
  end

  def self.aliases
    ['tomorrow']
  end

  def respond(m,args)
    w = WikiaDailies.new(1)
    reward = w.dungeon_reward
    groups = w.get_dailies
    rv = groups.each_with_index.map {|times, i| "#{(i + 65).chr}: #{times.join(' ')}"}
    rv = rv.join(" | ")
    m.reply "Tomorrow's dungeon is #{reward}"
    m.reply rv
    specials = w.specials
    if specials.count > 0
      m.reply "Special dungeon(s): #{specials.join(', ')}"
    end
  end
end

class TopicPlugin < PazudoraPluginBase
  BORDER = " \u2605 "
  DAYS = {1 => 'M', 2 => 'Tu', 3 => 'W', 4 => 'Th', 5 => 'F', 6 => 'Sa', 7 => 'Su'}

  def self.helpstring
"!pad settopic: Changes the topic of this channel to a summary of today's daily dungeon times.
Uses Pacific time. If it doesn't work, make sure that Asterbot has channel op."
  end

  def self.aliases
    ['settopic', 'topic']
  end

  def respond(m, args)	
    w = WikiaDailies.new
    reward = w.dungeon_reward
    groups = w.get_dailies(-8)
    supers = w.group_dragons(true)
    report = groups.each_with_index.map {|times, i| "#{(i + 65).chr}: #{times.join(' ')}"}.join(" | ")
    report = "[#{reward}] " + report
    if supers.length > 0
      report += " | SUPERS #{supers.join(', ')}"
    end
    report += " | #{DAYS[Time.now.wday]} #{Time.now.month}/#{Time.now.day} PST (-8)"
    if m.channel.topic.include?(BORDER)
      saved_topic = m.channel.topic.split(BORDER)[0..-2].join(BORDER)
      p "Attempting to set topic to #{saved_topic + BORDER + report}"
      m.channel.topic = saved_topic + BORDER + report
    else
      p "Attempting to set topic to #{m.channel.topic + BORDER + report}"
      m.channel.topic = m.channel.topic + BORDER + report
    end
  end
end

class WhenPlugin < PazudoraPluginBase
  def self.helpstring
"!pad when TZ: Provides a summary of today's daily dungeons for you. Your nick must be known to asterbot with a FC.
TZ can be any integer GMT offset (e.g -3), defaults to GMT-7 Pacific DST"
  end

  def self.aliases
    ['when']
  end

  def respond(m, args)
    if args
      timezone = args.to_i      
    else
      timezone = -8
    end
    user = User.fuzzy_lookup(m.user.nick)
    group_num = user ? user.group_number : 0
 
    dailies_array = PDXDailies.get_dailies(timezone)
    
    #example: ["10 am", "3 pm", "8 pm"]
    daily_times = dailies_array[group_num]

    result = ["Group #{(group_num + 65).chr}: #{PDXDailies.dungeon_reward}"]
    daily_times.each do |time_as_string|
      start_time = PDXDailies.string_to_time_as_seconds(time_as_string)

      minutes_until_start = ((start_time - Time.now)/60).to_i
      
      #Hasn't begun yet
      if minutes_until_start > 0
        result << "(in #{minutes_until_start/60}:#{(minutes_until_start % 60).to_s.rjust(2,'0')}, #{minutes_until_start / 10} stamina)"
      else
        #Currently ongoing
        if minutes_until_start > -60
          result << "(now! for #{minutes_until_start+60} minutes)"
        end
      end
      
    end
    
    m.reply(result.join(' | '))
    
  end
end

=end
