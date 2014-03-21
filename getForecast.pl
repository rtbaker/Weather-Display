#!/usr/bin/perl -w

use strict;

my $debug = 1;

use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use MetOffice;
use Data::Dumper;
use Getopt::Std;

# What are we doing ?
my $opt_string = 'hk:f:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
usage() if $opt{h};

my $apiKey = undef;

# Get the API key (stored in key.txt)
if (exists($opt{'k'})){
	$apiKey = $opt{'k'};
}
else {
	my $keyFile = 'key.txt';
	
	if (exists($opt{'f'}) && length($opt{'f'})){
		$keyFile = $opt{'f'};
	}
	
	open(my $fh, '<', $keyFile)
  	or die "Could not open file \"$keyFile\" $!";

		$apiKey = <$fh>;
		close ($fh);
}

if (!defined ($apiKey) || !length($apiKey)) { die "Error: No api key specified\n"; }
chomp $apiKey;

debug ("Using apiKey: " . $apiKey);

my $id = $ARGV[0];

if (!defined($id)) { die "No location id given"; }

if ($id !~ /^\d+$/){ die "Location id must be an integer"; }

debug ("Using location id: " . $id);

my $mOffice = new MetOffice(apiKey => $apiKey);

my $data = $mOffice->threeHourForecast($id);

my $first = $data->[0];

debug("Report for next 3 hours on " . $first->{'value'});

my $next = $first->{'Rep'}->[0];
my $code = $next->{'W'};
my %codes = $mOffice->weatherCodes();


print "Weather code is $code : " . $codes{$code} . "\n";
# ----------------------------------------------------------------------------------------------------------------

sub debug {
	if (!$debug) { return; }

	print "DEBUG: ";
	printf (@_);
	print "\n";
}

sub usage {
	print STDERR << "EOF";
Retrieve MetOffice Datapoint locations. If no option given, print out all locations.

usage: $0 [-h] [-k API key | -f  API key file] <location id>
	-h        		: this (help) message
  -k key				: Met Office API key
  -f keyfile    : File containing Met Office API key.
EOF
	
	exit;
}