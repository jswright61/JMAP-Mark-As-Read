# JMAP-Mark-Read

This is a pretty simple program to mark all unread emails in a given folder, Archive by default, as read.
It was written in Ruby. It uses net::http for HTTP requests to minimize external dependencies.

This program also demonstrates some core features of Fastmails JMAP API.

There may be other email roviders who support JMAP, but Fastmail is the one I am familiar with.

The program requires an API token, you can find out more about obtaining an API token at Fastmail's
[API Documentation Page](https://www.fastmail.com/dev/).

The program requires your API Token (with read/write permissions) to be available in an environment variable:

```
$ export FASTMAIL_API_KEY=fmu1_my_secret_token
```

or

```
$ FASTMAIL_API_KEY=fmu1_my_secret_token ruby fastmail_mark_archive_read.rb
```

Alternatively, you can provide it with a commandline argument when calling the program

```
$ ruby fastmail_mark_archive_read.rb --api-key=fmu1_my_secret_token
```

When run with just the api token supplied, the program will look up your account id and the id for your Archive folder.
It will print out these values to the terminal.
In the future, you may supply these values as commandline arguments.<br>
--account-id=my_account_id<br>
--mailbox-id=my_mailbox_id

If you want to mark unread emails as read in a folder other than Archive, you can supply that folder name as a
commandline argument as well. Keep in mind folder names are case ssensitive.<br>
--mailbox-name=my_mailbox_name
