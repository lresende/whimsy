#
# send feedback on reports
#

ASF::Mail.configure

# fetch minutes
@minutes = @agenda.sub('_agenda_', '_minutes_')
minutes_file = "#{AGENDA_WORK}/#{@minutes.sub('.txt', '.yml')}"
minutes_file.untaint if @minutes =~ /^board_minutes_\d+_\d+_\d+\.txt$/
date = @agenda[/\d+_\d+_\d+/].gsub('_', '-')

if File.exist? minutes_file
  minutes = YAML.load_file(minutes_file) || {}
else
  minutes = {}
end

# extract values for common fields
if @from
  from = @from
else
  sender = ASF::Person.find(env.user || ENV['USER'])
  from = "#{sender.public_name} <#{sender.id}@apache.org>".untaint
end

output = []

# iterate over the agenda
Agenda.parse(@agenda, :full).each do |item|
  # select exec officer, additional officer, and committee reports
  next unless item[:attach] =~ /^(4[A-Z]|\d|[A-Z]+)$/
  next unless item['chair_email']
  next unless @dryrun or @checked[item['title'].gsub(/\s/, '_')]

  # collect comments and minutes
  text = ''

  if item['comments'] and not item['comments'].empty?
    comments = item['comments'].gsub(/^(\S)/, "\n\\1")
    text += "\nComments:\n#{comments.gsub(/^/, '  ')}\n"
  end

  if minutes[item['title']]
    text += "\nMinutes:\n#{minutes[item['title']].gsub(/^/, '  ')}\n"
  end

  next if text.strip.empty?

  # build cc list
  cc = ['board@apache.org']
  
  if item['mail_list']
    if item[:attach] =~ /^[A-Z]+/
      cc << "private@#{item['mail_list']}.apache.org".untaint
    elsif item['mail_list'].include? '@'
      cc << item['mail_list'].untaint
    else
      cc << "#{item['mail_list']}@apache.org".untaint
    end
  end

  # construct email
  mail = Mail.new do
    from from
    to "#{item['owner']} <#{item['chair_email']}>".untaint
    cc cc
    reply_to cc
    subject "Board feedback on #{date} #{item['title']} report"

    body text.strip.untaint
  end

  mail.deliver! unless @dryrun

  # add to output
  output << {
    attach: item[:attach],
    title: item['title'],
    mail: mail.to_s
  }
end

# indicate that feedback has been sent
unless @dryrun
  minutes[:todos] ||= {}
  minutes[:todos][:feedback_sent] ||= []
  minutes[:todos][:feedback_sent] += output.map {|item| item[:title]}
  File.write minutes_file, YAML.dump(minutes)
  IPC.post type: :minutes, agenda: @agenda, value: minutes
end

# return output to client
output
