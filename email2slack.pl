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
# apt-get install libemail-filter-perl
# sudo cpan install Email::Filter
#
# apt-get install libwww-perl
# sudo cpan install Bundle::LWP
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

my $title = slack_escape($mail->header('subject'));
my $text = slack_escape($mail->body());

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
    "attachments": [
        {
            "fallback": "",
            "color": "#36a64f",
            "title": "$title",
            "text": "$text"
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
