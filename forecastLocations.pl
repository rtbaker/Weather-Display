#!/usr/bin/perl -w

use strict;

my $debug = 0;

use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use MetOffice;
use Data::Dumper;
use Getopt::Std;
use Google::GeoCoder::Smart;
use Geo::Distance;

# What are we doing ?
my $opt_string = 'hp:d:k:f:';
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

my $mOffice = new MetOffice(apiKey => $apiKey);

if (exists($opt{'p'})){
	# Search by postcode
	my $geo = Google::GeoCoder::Smart->new();
	my ($resultnum, $error, @results) = $geo->geocode("address" => $opt{'p'}, "city" => "", "state" => "", "zip" => "");

	if ($error ne "OK"){
		die "Google error: " . $error;
	}
	
	if (!$resultnum) {
		print "Postcode not recognised !\n";
	} else {
		my $result = $results[0];
		my $location = $result->{geometry}->{location};

		my $latitude = $location->{lat};
		my $longitude = $location->{lng};
		
		my $geo = new Geo::Distance;
		my $locations = $mOffice->allLocations();
		
		my $searchDistance = 5;
		if (exists($opt{'d'})){
			if ($opt{'d'} =~ /^\d+$/){
				$searchDistance = $opt{'d'};
			} else {
				print "Distance must be an integer, using 5 mile radius instead\n";
			}
		}
		
		foreach my $location (@{$locations}){
			my $distance = $geo->distance( 'mile', $longitude,$latitude => $location->{longitude},$location->{latitude} );
			
			# 5 mile radius for now
			if ($distance <= $searchDistance){
				printf "%-50s Id: %-11s Position: %s, %s\n", $location->{name}, $location->{id}, $location->{longitude}, $location->{latitude};
			}
		}
	}

	exit;
}

# If we get here then print all
my $locations = $mOffice->allLocations();

foreach my $location (@{$locations}){
	printf "%-50s Id: %-11s Position: %s, %s\n", $location->{name}, $location->{id}, $location->{longitude}, $location->{latitude};
}

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

usage: $0 [-h] [-p postcode] [ -k API key | -f API Key file ] [ -d search distance]
	-h        		: this (help) message
	-p postcode   : Postcode to search near
  -d distance   : Radius around search postcode to show results for (default 5 miles)
  -k key				: Met Office API key
  -f keyfile    : File containing Met Office API key.
EOF
	
	exit;
}