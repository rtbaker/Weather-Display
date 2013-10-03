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

# Get the API key (stored in key.txt)
open(my $fh, '<', 'key.txt')
  or die "Could not open file \"key.txt\" $!";

my $apiKey = <$fh>;
close ($fh);

if (!defined ($apiKey) || !length($apiKey)) { die "Error: No api key specified\n"; }
chomp $apiKey;

debug ("Using apiKey: " . $apiKey);

# What are we doing ?
my $opt_string = 'hp:';
my %opt;
getopts( "$opt_string", \%opt ) or usage();
usage() if $opt{h};

my $mOffice = new MetOffice(apiKey => $apiKey);

if (exists($opt{'p'})){
	# Search by postcode
	my $geo = Google::GeoCoder::Smart->new();
	my ($resultnum, $error, @results) = $geo->geocode("address" => $opt{'p'}, "city" => "", "state" => "", "zip" => "");

	if ($error ne "OK"){
		die "Google error: " . $error;
	}
	
	if (!$resultnum) {
		print "No results !\n";
	} else {
		my $result = $results[0];
		my $location = $result->{geometry}->{location};

		my $latitude = $location->{lat};
		my $longitude = $location->{lng};
		
		my $geo = new Geo::Distance;
		my $locations = $mOffice->allLocations();
		
		foreach my $location (@{$locations}){
			my $distance = $geo->distance( 'mile', $longitude,$latitude => $location->{longitude},$location->{latitude} );
			
			# 5 mile radius for now
			if ($distance <= 5){
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

usage: $0 [-h] [-p postcode]
	-h        		: this (help) message
	-p postcode   : Postcode to search near

EOF
	
	exit;
}