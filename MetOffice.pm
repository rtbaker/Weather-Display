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
use Text::CSV;

my %setup = (
	apiUrl 			=> "http://datapoint.metoffice.gov.uk/public/data/",
	apiKey			=> undef,
	codesFile 	=> "weatherCodes.csv",
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

#  Return the 5 day forecast in 3 hour steps
sub threeHourForecast {
	my $self = shift;
	my $id = shift or die "No site id given";
	
	if ($id !~ /^\d+$/){ die "Site id must be an interger"; }
	
	my $req = "val/wxfcs/all/xml/" . $id . "?res=3hourly";
	
	my $data = $self->doRequest($req, 'Period');
	
#	print Dumper ($data->{'DV'}->[0]->{'Location'}->[0]);
	return $data->{'DV'}->[0]->{'Location'}->[0]->{'Period'};
}

my %codes;

sub weatherCodes {
	my $self = shift;

	if (scalar(keys %codes) == 0){
		# Initialise
		use Text::CSV;
		my $csv = Text::CSV->new({ sep_char => ',' });

		open(my $data, '<', $self->{codesFile}) or die "Could not open '" . $self->{codeFile} . "' $!\n";

		while (my $line = <$data>) {
		  chomp $line;

		  if ($csv->parse($line)) {
		      my @fields = $csv->fields();
					$codes{$fields[0]} = $fields[1];
		  } else {
		      warn "Line could not be parsed: $line\n";
		  }
		}
	}
	
	return %codes;
}

# -----------------------------------------------------------------------------------------------------

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
		print "Error retrieving URL: " . $response->status_line . "\n";
		
		if ($response->code == 403){
			print "Invalid API Key ??\n";
		}
		
		return undef;
	}
 
#	print Dumper($response->decoded_content);
	
	my $xml =  XMLin($response->decoded_content,
		ForceArray => ($keyAttr),
		KeyAttr => []);

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

