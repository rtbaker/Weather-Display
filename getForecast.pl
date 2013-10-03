#!/usr/bin/perl -w

use strict;

my $debug = 1;

use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use MetOffice;
use Data::Dumper;

# Get the API key (stored in key.txt)
open(my $fh, '<', 'key.txt')
  or die "Could not open file \"key.txt\" $!";

my $apiKey = <$fh>;
close ($fh);

if (!defined ($apiKey) || !length($apiKey)) { die "Error: No api key specified\n"; }
chomp $apiKey;

debug ("Using apiKey: " . $apiKey);

my $id = $ARGV[0];

if (!defined($id)) { die "No location id given"; }

if ($id !~ /^\d+$/){ die "Location id must be an integer"; }


# ----------------------------------------------------------------------------------------------------------------

sub debug {
	if (!$debug) { return; }

	print "DEBUG: ";
	printf (@_);
	print "\n";
}