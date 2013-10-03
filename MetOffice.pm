# Perl library to support MetOffice Datapoint api
#
# 

package MetOffice;

use strict;
use warnings;

my $debug = 1;

use LWP::UserAgent;
use XML::Simple qw(:strict);
use Data::Dumper;

my %setup = (
	apiUrl => "http://datapoint.metoffice.gov.uk/public/data/",
	apiKey => undef
);

# Constructor
sub new
{
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;
		$self->initialise(%options);

    return $self;
}

# General setup
sub initialise
{
    my ($self, %options) = @_;

    # setup (need to at least specify apiKey)
    my ($key, $value);
    while (($key, $value) = each %setup)
    {
        $self->{$key} = defined $options{$key} ? $options{$key} : $value;
    }

    die "No API key has been specified\n" if ! defined $self->{apiKey};

    $self->{ua} = LWP::UserAgent->new();
}

# Get all available locations
sub allLocations {
	my $self = shift;
	
	my $req = "/val/wxfcs/all/xml/sitelist";
	
	my $data = $self->doRequest($req, 'Location');
	
	return $data->{'Location'};
}

# Get a request's data from the API, internal use.

sub doRequest {
	my $self = shift;
	my $req = shift or die "No request";
	my $keyAttr = shift or die "No KeyAttr specified";
	
	debug ("doRequest -> " . $req);
	
	my $fullUrl = $self->{apiUrl} . $req;
	
	# did the req already have arguments ?
	if ($fullUrl =~ /\?/){
		$fullUrl = $fullUrl . "&key=" . $self->{apiKey};
	} else {
		$fullUrl = $fullUrl . "?key=" . $self->{apiKey};
	}
	
	debug ("doRequest full URL -> " . $fullUrl);
	
	my $response = $self->{ua}->get($fullUrl);
	
	if (!$response->is_success){
		warn "Error retrieving URL: " . $response->status_line;
		return undef;
	}
 
	my $xml =  XMLin($response->decoded_content,
		ForceArray => ($keyAttr),
		KeyAttr => ($keyAttr));

	return $xml;
}

# ----------------------------------------------------------------------------------------------------------------

sub debug {
	if (!$debug) { return; }

	print "MetOffice.pm DEBUG: ";
	printf (@_);
	print "\n";
}

1;

