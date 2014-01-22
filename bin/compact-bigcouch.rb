#!/usr/bin/env ruby

# Note the use of the "front door" BigCouch port.

require 'json'
require 'net/http'
require 'getoptlong'

opts = GetoptLong.new(
#  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--database', '-d', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--shard', '-s', GetoptLong::REQUIRED_ARGUMENT ],  # Example: e0000000-ffffffff
)

params = {}
opts.each {|opt, arg| params[opt.gsub(/^--/, '')] = arg }

raise "Missing required --database arg with repository/database URL" if params['database'].nil?

def get(url)
  Net::HTTP.get(URI(url))
end

def post(url, request_headers)
  #TODO: convert to taking a full URI instance
  uri = URI(url)
  req = Net::HTTP::Post.new(uri.path)
  req["Content-Type"] = "application/json"
  if request_headers.any?
    req.basic_auth request_headers[:username], request_headers[:password]
  end

  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
  
  case res
  when Net::HTTPSuccess, Net::HTTPRedirection
    true
  else
    raise "HTTP POST call failed: #{ res.value }"
  end
end

# curl -H "Content-Type: application/json" -X POST http://USER:PASS@repo-node3:5986
# /shards%2Fe0000000-ffffffff%2Fdashboard.1372038665/_compact/all_provider_docs

def get_shards(host)
  JSON.parse(get(host + '_all_dbs'))
end

def run_view_cleanup(database_url)
  post(database_url + '/_view_cleanup', {})
end

def main(params)
  repo_uri = URI.parse(params['database'])
  request_headers = {
    :username => repo_uri.user,
    :password => repo_uri.password
  }
  
  target_database = repo_uri.path.match(/^\/(.+)$/)[1]
  backdoor_host = 'http://' + repo_uri.host + ':' + (repo_uri.port + 2).to_s + '/'
  frontdoor_host = 'http://' + repo_uri.host + ':' + (repo_uri.port).to_s + '/'
  compact_api_prefix = backdoor_host + 'shards%2F'

  if compact_running(frontdoor_host)
    puts "Compaction already running on #{repo_uri.host}: #{compact_running(frontdoor_host)}"
    exit 0
  end

  # Always start with view compaction for this database
  run_view_cleanup(frontdoor_host + target_database)

  get_shards(backdoor_host).shuffle.each do |path|
    next unless path =~ /^shards\/(.+)\/(#{target_database}\.\d+)$/
    shard, database = $1, $2

    # limit to requested shard if there was one
    next if params['shard'] && params['shard'] != shard

    url = compact_api_prefix + shard + '%2F' + database + '/_compact'
    logmsg "Compacting database shard #{shard}/#{database} -> #{url}"

    post(url, request_headers)

    while true do
      sleep 5
      running = compact_running(frontdoor_host)
      break if running.nil?
      logmsg running
    end
    
  end
end

def logmsg(msg)
  puts "[#{Time.now.to_s}] #{msg}"
end

def compact_running(base_endpoint)
  # Do not use the more obvious API endpoint because it lies 5% of
  # the time: JSON.parse(HTTParty.get(endpoint))['compact_running']
  json = JSON.parse(get(base_endpoint + '_active_tasks'))
  #view comapction looks like this: [{"type":"View Group Compaction","task":"shards/e0000000-ffffffff/dashboard.1372038665/all_provider_docs","status":"Copied 100000 of 1788853 Ids (5%)","pid":"<0.3620.746>"}]

  hostname = URI.parse(base_endpoint).host
  entry = json.detect {|x| x['node'] =~ /\b#{hostname}\b/ && x['type'] == 'Database Compaction'}

  entry.nil? ? nil : "#{ entry['task'] } - #{entry['status'] }"
end

main(params)

