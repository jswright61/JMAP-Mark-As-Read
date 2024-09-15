#!/usr/bin/env ruby

require "net/http"
require "net/https"
require "json"

ARGV.each do |arg|
  if (api_match=arg.match(/\A--api-key=(.+)\z/))
    API_KEY = api_match[1]
  elsif (mailbox_name_match=arg.match(/\A--mailbox-name=(.+)\z/))
    MAILBOX_NAME = mailbox_name_match[1]
  elsif (mailbox_id_match=arg.match(/\A--mailbox-id=(.+)\z/))
    MAILBOX_ID = mailbox_id_match[1]
  elsif (account_id_match=arg.match(/\A--account-id=(.+)\z/))
    ACCOUNT_ID = account_id_match[1]
  end
end

if !defined?(API_KEY)
  if ENV["FASTMAIL_API_KEY"].nil?
    raise StandardError("You must supply an API Key either as a commandline argument or environment variable.
      Please see the README.")
  else
    API_KEY = ENV["FASTMAIL_API_KEY"]
  end
end

if !defined?(MAILBOX_NAME)
  MAILBOX_NAME = "Archive"
end


def first_account_id()
  uri = URI("https://api.fastmail.com/jmap/session")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  req = Net::HTTP::Get.new(uri)
  req.add_field "Authorization", "Bearer #{API_KEY}"

  resp = http.request(req)
  account_id = JSON.parse(resp.body)["accounts"].keys.first
  puts "First account_id is: #{account_id}"
  account_id
rescue => e
  puts "HTTP Request failed (#{e.message})"
  exit
end

def api_request(method_calls)
  uri = URI("https://api.fastmail.com/jmap/api/")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  params = {
    "using" => [
      "urn:ietf:params:jmap:core",
      "urn:ietf:params:jmap:mail"
    ],
    "methodCalls" => method_calls
  }
  body = JSON.dump(params)

  req = Net::HTTP::Post.new(uri)
  req.add_field "Authorization", "Bearer #{API_KEY}"
  req.add_field "Content-Type", "application/json"
  req.body = body

  http.request(req)
rescue => e
  puts "HTTP Request failed (#{e.message})"
  exit
end

def mailbox_id(account_id, mailbox_name)
  method_calls = [[
    "Mailbox/query",
    {"filter" => {"name" => mailbox_name}, "accountId" => account_id},
    "a"
  ]]
  resp = resp = api_request(method_calls)
  mailbox_id = JSON.parse(resp.body)["methodResponses"][0][1]["ids"][0]
  puts "mailbox_id for the [#{mailbox_name}] folder is: #{mailbox_id}"
  mailbox_id
end

def mark_read(account_id, email_ids)
  start_el = 0
  marked_unread = 0
  while start_el < email_ids.count
    method_calls = email_ids[start_el, 50].map do |eml|
      [ "Email/set", {accountId: account_id, update: {"#{eml}": {"keywords/$seen": true}}}, "0" ]
    end
    api_request(method_calls)
    marked_unread += (email_ids[start_el, 50]).count
    start_el += 50
  end
  marked_unread
end

def unread_mail_ids(account_id, mailbox_id)
  method_calls = [["Email/query",
    {
      accountId: account_id, filter: {inMailbox: mailbox_id, notKeyword: "$seen"},
      sort: [{property: "receivedAt", isAscending: false}],
      limit: 500
    },
    "a"]]
  resp = api_request(method_calls)
  JSON.parse(resp.body)["methodResponses"][0][1]["ids"]
end

def read_mail_ids(account_id, mailbox_id)
  method_calls = [["Email/query",
    {
      accountId: account_id, filter: {inMailbox: mailbox_id, hasKeyword: "$seen"},
      sort: [{property: "receivedAt", isAscending: false}],
      limit: 500
    },
    "a"]]
  resp = api_request(method_calls)
  JSON.parse(resp.body)["methodResponses"][0][1]["ids"]
end

def mark_unread(account_id, email_ids)
  start_el = 0
  marked_read = 0
  while start_el < email_ids.count
    method_calls = email_ids[start_el, 50].map do |eml|
      [ "Email/set", {accountId: account_id, update: {"#{eml}": {"keywords/$seen": nil}}}, "0" ]
    end
    api_request(method_calls)
    marked_read += (email_ids[start_el, 50]).count
    start_el += 50
  end
  marked_read
end

if !defined?(ACCOUNT_ID)
  ACCOUNT_ID = first_account_id()
end

if !defined?(MAILBOX_ID)
  MAILBOX_ID = mailbox_id(ACCOUNT_ID, MAILBOX_NAME)
end
unread_ids = unread_mail_ids(ACCOUNT_ID, MAILBOX_ID)
marked_read = mark_read(ACCOUNT_ID, unread_ids)
if marked_read == 1
  puts "1 email was marked as read."
else
  puts "#{marked_read} emails were marked as read."
end
