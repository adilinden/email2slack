#!/usr/bin/perl -w
#
# Copyright 2018 Adi Linden <adi@adis.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Installation
# ------------
#
# Just need some perl modules. Depending on environment can use Debian
# packages or install via CPAN.
#
#   apt-get install libemail-filter-perl
#   apt-get install libwww-perl
#
# or
#
#   sudo cpan install Email::Filter
#   sudo cpan install Bundle::LWP
#
# Install this script via git
#
#   cd /usr/local/lib
#   git clone https://github.com/adilinden/email2slack.git
#
# Hook into local MTA by adding to /etc/aliases something like this
#
#   webbot-test: "|/usr/bin/perl /usr/local/lib/email2slack/email2slack.pl"
#
# Run the `newaliases` command to update the aliases database.
#
#
# SLACK
# -----
#
# A SLACK workspace is tremendously helpful. As is the URL for a SLACK
# incoming webhook.
#
# To setup the incoming webhook:
# https://my.slack.com/services/new/incoming-webhook/
#
# The incoming webhook docs:
# https://api.slack.com/incoming-webhooks
# https://api.slack.com/docs/message-attachments
#
#
# Zenoss
# ------
#
# Configured Zenoss email notifications to be formatted as follows in
# Events > Triggers > Notifications as follows:
# 
# Down Message
# 
# Subject Format: ${evt/device} is DOWN!
# 
# Body Format:    Device: ${evt/device}
#                 Time: ${evt/lastTime}
#                 Message: ${evt/message}
#                 More at <url of choice> ...
# 
# Clear Message
# 
# Subject Format: ${evt/device} RECOVERED!
# 
# Body Format:    Device: ${evt/device}
#                 Time: ${evt/lastTime}
#                 Message: ${evt/message}
#                 More at <url of choice> ...
# 

use strict;
use warnings;
use utf8;

# Email
use Email::Filter;

# LWP
use LWP::UserAgent;

##
## Define SLACK incoming webhook
##
my $slack_webhook_url = "https://hooks.slack.com/services/something/something";

##
## Exit if no piped input
##
exit if (-t STDIN);

##
## Handle email content
##
my $mail = Email::Filter->new();

my $mail_from    = slack_escape($mail->header('from'));
my $mail_to      = slack_escape($mail->header('to'));
my $mail_subject = slack_escape($mail->header('subject'));
my $mail_body    = slack_escape($mail->body());

# Colour the output
my $colour = "#aaaaaa";
$colour = "#dd1010" if ($mail_subject =~ m/down/i);
$colour = "#10dd10" if ($mail_subject =~ m/recovered/i);

##
## Handle SLACK webhook
##
my $ua = LWP::UserAgent->new;
 
# set custom HTTP request header fields
my $req = HTTP::Request->new(POST => $slack_webhook_url);
$req->header('content-type' => 'application/json');
 
# add POST data to HTTP request body
my $post_data = <<EOD;
{
    "text": "*$mail_subject*",
    "attachments": [
        {
            "fallback": "",
            "color": "$colour",
            "text": "*From:* $mail_from\n*Subject:* $mail_subject\n\n$mail_body"
        }
     ]
}
EOD

$req->content($post_data);
 
my $resp = $ua->request($req);
if ($resp->is_success) {
    my $message = $resp->decoded_content;
    print "Received reply: $message\n";
}
else {
    print "HTTP POST error code: ", $resp->code, "; ";
    print "HTTP POST error message: ", $resp->message, "\n";
}

##
## Escape text
##
sub slack_escape {
    my ($s) = @_;

    # Escape per SLACK docs
    # https://api.slack.com/docs/message-formatting#how_to_escape_characters
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;

    # Escape JSON special characters
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\n/\\n/g;

    return $s;
}
