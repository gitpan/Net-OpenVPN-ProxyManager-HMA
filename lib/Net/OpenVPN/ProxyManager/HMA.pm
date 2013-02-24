package Net::OpenVPN::ProxyManager::HMA;
use LWP::Simple;
use Moose;
use 5.10.0;
extends 'Net::OpenVPN::ProxyManager';

our $VERSION = '0.021';

has hma_server_list => (is => 'rw', isa => 'ArrayRef', builder => '_get_server_list');
has hma_config 		=> (is => 'rw', isa => 'Str', builder => '_get_hma_config');

=head1 NAME

Net::OpenVPN::ProxyManager::HMA - connect to HideMyAss.com (HMA) proxy servers using OpenVPN.

=head1 SYNOPSIS

	use Net::OpenVPN::ProxyManager::HMA;
	
	my $pm_hma = Net::OpenVPN::ProxyManager::HMA->new;
	my $servers = $pm_hma->get_servers({ name => 'usa', proto => 'tcp'});
	$pm_hma->connect_to_random_server($servers);

	
=cut


=head1 DESCRIPTION

L<Net::OpenVPN::ProxyManager::HMA> is an object oriented module that makes it easier to connected to 
HMA proxy servers by automatically downloading the latest list of available HMA proxy servers and the OpenVPN connection
configuration (this is done at construction of the object).


=head1 DEPENDENCIES

To login to the HMA proxy servers, you will need to have an active account with HMA 
(http://hidemyass.com). I am not affiliated with HMA other than as a customer.

See L<Net::OpenVPN::ProxyManagerA> for other dependencies.

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

=head1 METHODS

=head2 get_servers

This method returns an arrayhash of HMA servers available (the list is downloaded upon 
construction - Net::OpenVPN::ProxyManager::HMA->new). If no arguments are passed to this
method, it will return the entire arrayhash of available servers (approximately 350).

The method accepts two optional string arguments as key value pairs:

=over

=item *
Name, this is a string of the location name. HMA provide a location name string in the format: "Canada, Ontario, Toronto (LOC1 S1)".

=item *
Proto, this is the protocol option and can be either TCP or UDP. Many of the HMA servers accept both protocols.

=back

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

	my $pm_hma->hma_connect({
		'ip' 			=> '104.202.33.5',
		'name' 			=> 'Canada, Ontario, Toronto (LOC1 S1)',
		'country_code' 	=> 'ca',
		'tcp_flag'		=> 'TCP',
		'udp_flag'		=> 'UDP',
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

=head2 get_ip_address

Will return your current IP address or 0 if the ip lookup is not successful (uses an HMA web service).

=cut

sub get_ip_address {
	my $self = shift;
	my $ip_address = get('http://geoip.hidemyass.com/ip/');
	$ip_address ? $ip_address : 0;
}


no Moose;
1;

=head1 AUTHOR

David Farrell, C<< <davidnmfarrell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-openvpn-proxymanager-hma at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-OpenVPN-ProxyManager>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::OpenVPN::ProxyManager::HMA


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-OpenVPN-ProxyManager-HMA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-OpenVPN-ProxyManager-HMA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-OpenVPN-ProxyManager-HMA>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-OpenVPN-ProxyManager-HMA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Farrell.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
