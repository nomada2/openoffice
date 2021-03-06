#**************************************************************
#  
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#  
#    http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.
#  
#**************************************************************



package installer::mail;

use Net::SMTP;
use installer::converter;
use installer::exiter;
use installer::ziplist;

#########################################
# Sending a mail
#########################################

sub send_mail
{
	my ($message, $listenerstring, $mailinfostring, $languagesref, $destdir) = @_;
	
	my $listener = installer::converter::convert_stringlist_into_array($listenerstring, ",");
	my $mailinfo = installer::converter::convert_stringlist_into_array($mailinfostring, ",");

	my @listener = ();

	for ( my $i = 0; $i <= $#{$listener}; $i++ ) { push(@listener, ${$listener}[$i]); }
	for ( my $i = 0; $i <= $#{$mailinfo}; $i++ ) { ${$mailinfo}[$i] =~ s/\s*$//g; }

	my $smtphost = ${$mailinfo}[0];
	my $account = ${$mailinfo}[1];
	my $sender = ${$mailinfo}[2];

	if ( ! $smtphost ) { installer::exiter::exit_program("ERROR: Could not read SMTP Host in list file!", "send_mail"); }
	if ( ! $account ) { installer::exiter::exit_program("ERROR: Could not read Account in list file!", "send_mail"); }
	if ( ! $sender ) { installer::exiter::exit_program("ERROR: Could not read Sender in list file!", "send_mail"); }

	my $subject = "";
	my $basestring = $installer::globals::product . " " . $installer::globals::compiler . $installer::globals::productextension . " " . $installer::globals::build. " " . $installer::globals::buildid . " " . $$languagesref . "\n";
	if ( $message eq "ERROR" ) { $subject = "ERROR: $basestring" }
	if ( $message eq "SUCCESS" ) { $subject = "SUCCESS: $basestring" }

	my @message = ();
	
	my $recipient_string = join ',', @listener;
	push(@message, "Subject: $subject");
	push(@message, "To: $recipient_string");
	push(@message, "\n");
	push(@message, "Located at $destdir");

	if ( $message eq "ERROR" ) 
	{
		for ( my $j = 0; $j <= $#installer::globals::errorlogfileinfo; $j++ )
		{
			my $line = $installer::globals::errorlogfileinfo[$j];
			$line =~ s/\s*$//g;
			push(@message, $line);
		}
	}

	for ( my $i = 0; $i <= $#message; $i++ ) { $message[$i] = $message[$i] . "\015\012"; }

	my $smtp = Net::SMTP->new( $smtphost, Hello => $account, Debug => 0 );

	# set sender
	$smtp->mail($sender);

	# listener
	my @good_addresses = ();
	$smtp->recipient( @listener, { SkipBad => 1 } );

	# send message		
	$smtp->data(\@message);

	# quit server
	$smtp->quit();
}

sub send_fail_mail
{
	my ($allsettingsarrayref, $languagestringref, $errordir) = @_;

	# sending a mail into the error board
	my $listener = "";
	$listener = installer::ziplist::getinfofromziplist($allsettingsarrayref, "fail");
	
	if ( $$listener )
	{ 
		my $mailinfo = installer::ziplist::getinfofromziplist($allsettingsarrayref, "mailinfo");
		
		if ( $$mailinfo ) { send_mail("ERROR", $listener, $mailinfo, $languagestringref, $errordir); }
		else { installer::exiter::exit_program("ERROR: Could not read mailinfo in list file!", "send_fail_mail"); }
    }
}			

sub send_success_mail
{
	my ($allsettingsarrayref, $languagestringref, $completeshipinstalldir) = @_;

	# sending success mail
	my $listener = "";
	$listener = installer::ziplist::getinfofromziplist($allsettingsarrayref, "success");

	if ( $$listener )
	{
		my $mailinfo = installer::ziplist::getinfofromziplist($allsettingsarrayref, "mailinfo");

		if ( $$mailinfo ) { send_mail("SUCCESS", $listener, $mailinfo, $languagestringref, $completeshipinstalldir); }
		else { installer::exiter::exit_program("ERROR: Could not read mailinfo in list file!", "send_success_mail"); }

	}
}			


1;
