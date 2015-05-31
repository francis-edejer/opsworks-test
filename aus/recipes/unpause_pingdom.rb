#!/usr/bin/env ruby

require 'net/https'
require 'pp'
require 'json'

PINGDOM_API_URL = 'https://api.pingdom.com'
PINGDOM_API_KEY = '9ps0iu3xy998wb2cj6x7ytwmhjgtv0s0'
PINGDOM_API_USERNAME = 'jd@binaries.sg'
PINGDOM_API_PASSWORD = '13f1a011a8770679'

def get_pingdom(append_url)
  begin
    uri = URI.parse(PINGDOM_API_URL)
    response = nil
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start {|https|
      req = Net::HTTP::Get.new(append_url)
      req.basic_auth PINGDOM_API_USERNAME, PINGDOM_API_PASSWORD
      req["App-Key"] = PINGDOM_API_KEY
      response = https.request(req)
      }
    return response
  rescue
      p $!
  end
end

def put_pingdom(append_url, body)
  begin
    uri = URI.parse(PINGDOM_API_URL)
    response = nil
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start {|https|
      req = Net::HTTP::Put.new(append_url, initheader = { 'Content-Type' => 'text/plain'})
      req.body = body
      req.basic_auth PINGDOM_API_USERNAME, PINGDOM_API_PASSWORD
      req["App-Key"] = PINGDOM_API_KEY
      response = https.request(req)
      }
    return response
  rescue
    p $!
  end
end

def list_all_checks_status()
  begin
    $PINGDOMSET = Array.new(50) {Array.new(3)}
    $PINGDOM_COUNT = 0
    append_url = '/api/2.0/checks'
    resp = get_pingdom(append_url)
    if resp
      if resp.code == '200'
        result = JSON.parse(resp.body)
        result["checks"].map { |ih|
          ih.values_at("name", "status", "id")
        }
        counter_result = result["checks"].count - 1
        (0..counter_result).each do |sk|
          $PINGDOMSET[sk][0] = result["checks"][sk]["name"]
          $PINGDOMSET[sk][1] = result["checks"][sk]["id"]
          $PINGDOMSET[sk][2] = result["checks"][sk]["status"]
        end
        $PINGDOM_COUNT = $PINGDOMSET.count - 1
        return $PINGDOMSET
      else
        p resp
      end
    end
  rescue
    p $!
  end
end

def update_status(cname,flag) # flag = pause / unpause
  begin
    id = cname
    if flag == "pause"
      pause_flag = true
    elsif flag == "unpause"
      pause_flag = false
    else
      puts "Unknown flag"
    end
    append_update_url = "/api/2.0/checks/#{id}"
    update_body = "paused=#{pause_flag}"
    update_resp = put_pingdom(append_update_url,update_body)
    if update_resp
      if update_resp.code == '200'
        update_result = JSON.parse(update_resp.body)
        return update_result["message"]
      else
        p update_resp
      end
    else
      puts "Failed to update Pingdom status."
    end
  rescue
    p $!
  end
end

list=list_all_checks_status()
host=`hostname -s`.strip
count = list.count - 1
match = 0
region=`curl -s 169.254.169.254/latest/meta-data/placement/availability-zone`
region.chop!
(0..count).each do |x|
  if list[x][0] != nil && list[x][0].include?(host) && list[x][0].include?(region) then
    match += 1
    if list[x][2] == "paused"
      update=update_status(list[x][1],'unpause')
      puts update
    else
      puts "Pingdom check already running"
    end
  end
end
if match == 0
 puts "Instance hostname can't be found in pingdom check list"
end
