#!/usr/bin/perl -w
use Modern::Perl;
use NewBackend;
use IO::Socket::INET;
use Proc::Daemon;

my $server_ip;
my $server_port;

if(@ARGV) { $server_ip = $ARGV[0];
			$server_port = $ARGV[1];}

# Хардкоде
$server_ip = "192.168.0.68";
$server_port = "8080";
# Хардкоде

# Создание сервера
my $socket = new IO::Socket::INET (
	LocalHost => $server_ip,
	LocalPort => $server_port,
	Proto => 'tcp',
	Listen => 5,
	Reuse => 1
);
die "Ошибка создания сокета $!\n" unless $socket;

while(1)
{
	my $client_socket = $socket->accept();
	my $client_address = $client_socket->peerhost();
	my $client_port = $client_socket->peerport();

	my $client_data;
	my $lgdata;
	my @array_client_data;
	my $url;

	$client_socket->recv($client_data, 1024);
	$lgdata = length($client_data);

	@array_client_data = split /\s/, $client_data;
	$url = $array_client_data[1];
	$url =~ s/%20/ /;

	# Передаём браузеру базовые заголовки
	$client_socket->send(http_headers());

	if ($url ne '/favicon.ico' and $url ne '/robots.txt') {

		my @data = process_request($url);
		if (@data) {
			if ($data[0] eq "yep" or $data[0] eq "nop") {$client_socket->send("<html>". $data[0]. "</html>");}
			else { $client_socket->send( http_respone(@data) ); }
		}
		else { $client_socket->send( not_found() ); }

		shutdown($client_socket, 1);
	}

	shutdown($client_socket, 1);
}
$socket->close();

# Формируем HTTP заголовки
sub http_headers { 
	return <<RESPONSE;
HTTP/1.0 200 OK
Server: PerlServer
Content-type: text/html; charset=UTF-8
Connection: close

RESPONSE
}

sub not_found {
	return "<html>Данные не найдены!</html>";
}

# Чтение полученного от бэкэнда каталога и подготовка его к выводу в формате HTML
sub http_respone {
	my( @catalog ) = @_;
	my $data_respone = "";
	my $size_array = @catalog;

	for ( my $i = 0; $i < $size_array; $i++ ) {
		my $hash = $catalog[$i];
		while( my ( $key1, $value1) = each %$hash ) {
			if ( $key1 eq "Information" ) {
				while( my ( $key2, $value2 ) = each %$value1 ) {
					$data_respone .= "<p> $key2 - $value2 </p>";
				}
			}
			elsif ( $key1 ne "new_order" ) { $data_respone .= "<p> $key1 - $value1 </p>"; }
		}
		$data_respone .= "<hr>";
	}
	return "<html>$data_respone</html>";
}