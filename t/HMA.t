use Test::More tests => 3;

use_ok ('Net::OpenVPN::ProxyManager::HMA');
ok (my $pm_hma = Net::OpenVPN::ProxyManager::HMA->new, 'Instantiate Net::OpenVPN::ProxyManager::HMA object');
ok (my $servers = $pm_hma->get_servers({ name => 'usa', proto => 'tcp'}), 'Check get_servers method');
