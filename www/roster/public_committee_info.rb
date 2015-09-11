require 'json'
require 'whimsy/asf'

# parse arguments for output file name
if ARGV.length == 0 or ARGV.first == '-'
  output = STDOUT
else
  # exit quickly if there has been no change
  if File.exist? ARGV.first
    source = "#{ASF::SVN['private/committers/board']}/committee-info.txt"
    mtime = [File.mtime(source), File.mtime(__FILE__)].max
    exit 0 if File.mtime(ARGV.first) >= mtime
  end

  output = File.open(ARGV.first, 'w')
end

# gather committee info
committees = ASF::Committee.load_committee_info
info = {last_updated: ASF::Committee.svn_change}
info[:committees] = Hash[committees.map {|committee|
  schedule = committee.schedule.to_s.split(/,\s*/)
  schedule.unshift committee.report if committee.report != committee.schedule

  [committee.name.gsub(/[^-\w]/,''), {
    display_name: committee.display_name,
    mail_list: committee.mail_list,
    established: committee.established,
    report: schedule,
    chair: Hash[committee.chairs.map {|chair|
      [chair.delete(:id), chair]}],
    roster: committee.roster,
    pmc: !ASF::Committee.nonpmcs.include?(committee)
  }]
}]

# output results
output.puts JSON.pretty_generate(info)
output.close