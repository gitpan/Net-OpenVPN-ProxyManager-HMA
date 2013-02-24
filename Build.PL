use Module::Build;
my $build = Module::Build->new(
	dist_name 			=> 'Net-OpenVPN-ProxyManager-HMA',
	dist_author			=> 'David Farrell <davidnmfarrell@gmail.com>',
	dist_version_from	=> 'lib/Net/OpenVPN/ProxyManager/HMA.pm',
	license				=> 'artistic',
	requires			=> { Moose 		   				=> '2.0603',
							 LWP::Simple   				=> '6',
							 perl		   				=> '5.10.0',
							 Net::OpenVPN::ProxyManager => '0.03',
							},
	configure_requires => { 'Module::Build' => 0.40 },
);
$build->create_build_script;
