package Net::OpenVPN::ProxyManager::HMA;
use LWP::Simple;
use Moose;
use 5.10.0;
extends 'Net::OpenVPN::ProxyManager';

our $VERSION = '0.011';

has hma_server_list => (is => 'rw', isa => 'ArrayRef', builder => '_get_server_list');
has hma_config 		=> (is => 'rw', isa => 'Str', builder => '_get_hma_config');

=head1 NAME

OpenVPN::ProxyManager::HMA - connect to HideMyAss.com (HMA) proxy servers using OpenVPN.

=head1 SYNOPSIS

	use Net::OpenVPN::ProxyManager::HMA;
	
	my $pm_hma = Net::OpenVPN::ProxyManager::HMA->new;
	my $servers = $pm_hma->get_servers({ name => 'usa', proto => 'tcp'});
	$pm_hma->connect_to_random_server($servers);
	

=head1 DESCRIPTION

L<Net::OpenVPN::ProxyManager::HMA> is an object oriented module that makes it easier to connected to 
HMA proxy servers by automatically downloading the latest list of available HMA proxy servers and the OpenVPN connection
configuration (this is done at construction of the object).


=head1 Dependencies (non-Perl)

To login to the HMA proxy servers, you will need to have an active account with HMA 
(http://hidemyass.com). I am not affiliated with HMA other than as a customer.

See L<Net::OpenVPN::ProxyManager> for other dependencies.

=cut

sub _get_hma_config {
	my $self = shift;
	my $hma_config_string = get('https://securenetconnection.com/vpnconfig/openvpn-template.ovpn');	
	$hma_config_string ? $hma_config_string : 0;	
}

sub _get_server_list {
	my $self = shift;
	my $hma_server_list_string = get('https://securenetconnection.com/vpnconfig/servers-cli.php');
	$hma_server_list_string ? $self->_parse_server_list_string($hma_server_list_string) : 0;
}

sub _parse_server_list_string {
	my ($self, $hma_server_list_string) = @_;
	my $server_list_arrayhash;
	my @server_list = split qr/\n/, $hma_server_list_string;
	for my $server (@server_list) {
		my @server_data = split qr/\|/, $server;
		push @{$server_list_arrayhash}, {
			'ip' 			=> $server_data[0],
			'name' 			=> $server_data[1],
			'country_code' 	=> $server_data[2],
			'tcp_flag'		=> $server_data[3],
			'udp_flag'		=> $server_data[4],
			'norandom_flag' => $server_data[5],
		};
	}
	return $server_list_arrayhash;
}
=head2 get_servers

This method returns an arrayhash of HMA servers available (the list is downloaded upon 
construction - Net::OpenVPN::ProxyManager::HMA->new). If no arguments are passed to this
method, it will return the entire arrayhash of available servers (approximately 350).

The method accepts two optional string arguments as key value pairs:
-Name, this is a string of the location name. HMA provide a location name string in the 
 format: "Canada, Ontario, Toronto (LOC1 S1)".
-Proto, this is the protocol option and can be either TCP or UDP. Many of the HMA servers 
 accept both protocols.

Example
	my $usa_tcp_servers_arrayhash = $pm_hma->get_servers({name => 'usa', proto => 'tcp'});

=cut

sub get_servers {
	my ($self, $server_params_hashref) = @_;
	my $server_list_arrayhash;
	if (exists $server_params_hashref->{name} and not exists $server_params_hashref->{proto}){
		push @{$server_list_arrayhash},	grep { 
			$_->{name} =~ m/$server_params_hashref->{name}/i} @{$self->hma_server_list};
	}
	elsif (exists $server_params_hashref->{proto} and not exists $server_params_hashref->{name}){
		for ($server_params_hashref->{proto}) {
			when (qr/tcp/i) {
				push @{$server_list_arrayhash},	grep { $_->{tcp_flag}
					} @{$self->hma_server_list};
			}
			when (qr/udp/i) {
				push @{$server_list_arrayhash},	grep { $_->{udp_flag}
					} @{$self->hma_server_list};
			}	
		}
	}
	elsif (exists $server_params_hashref->{proto} and exists $server_params_hashref->{name}){
		for ($server_params_hashref->{proto}) {
			when (qr/tcp/i) {
				push @{$server_list_arrayhash},	grep { $_->{tcp_flag} and 
					$_->{name} =~ m/$server_params_hashref->{name}/i} @{$self->hma_server_list};
			}
			when (qr/udp/i) {
				push @{$server_list_arrayhash},	grep { $_->{udp_flag} and
					$_->{name} =~ m/$server_params_hashref->{name}/i} @{$self->hma_server_list};
			}	
		}
	}
	else {
		push @{$server_list_arrayhash}, $self->hma_server_list;
	}
	return $server_list_arrayhash;
}

=head2 connect_to_random_server

This method will invoke the hma_connect method on a random server when this method is
called with an arrayhash of servers (as returned by the get_servers method).

Example
	$pm_hma->connect_to_random_server($arrayhash_of_servers);

=cut

sub connect_to_random_server {
	my ($self, $server_list_arrayhash) = @_;
	my $server_hashref = $server_list_arrayhash->[int(rand(@{$server_list_arrayhash}-1))];
	print 'Connecting to server ' . $server_hashref->{name} .' '. $server_hashref->{ip} ."\n";
	$self->hma_connect($server_hashref);
}

=head2 hma_connect

The hma_connect method will initialise the OpenVPN program to a server with the HMA
configuration. This method requires a hashref containing the attributes of the
server (this is the same hashref format that is returned by the get_servers method).

Example
	my $pm_hma->hma_connect({
			'ip' 		=> '104.202.33.5',
			'name' 		=> 'Canada, Ontario, Toronto (LOC1 S1)',
			'country_code' 	=> 'ca',
			'tcp_flag'	=> 'TCP',
			'udp_flag'	=> 'UDP',
			'norandom_flag' => undefined
		});

=cut

sub hma_connect {
	my ($self, $server_hashref) = @_;
	return 0 unless defined $server_hashref;
	my $hma_config = $self->hma_config;
	if ($server_hashref->{udp_flag}) {
		$hma_config .= "\n" . 'remote ' . $server_hashref->{ip} . ' 53' .
			"\n" . 'proto udp' . "\n";
	}
	else {
		$hma_config .= "\n" . 'remote ' . $server_hashref->{ip} . ' 443' .
			"\n" . 'proto tcp' . "\n";
	}
	$self->connect($hma_config);
}

no Moose;
1;
