#!/usr/bin/perl -w
use Modern::Perl;
use NewBackend;
use Data::Dumper;
use HTTP::Daemon;
use HTTP::Status;

my $server_ip;
my $server_port;

if(@ARGV) { $server_ip = $ARGV[0];
			$server_port = $ARGV[1];}

# Хардкоде
$server_ip = "192.168.0.68";
$server_port = "8080";
# Хардкоде

my $server = new HTTP::Daemon
	LocalAddr => $server_ip,
	LocalPort => $server_port;

while ( my $socket = $server->accept ) {
    while ( my $request = $socket->get_request ) {
        my $url = $request->url->path;
        $url =~ s/%20/ /;
        say $url;
        # Передаём браузеру заголовки
        $socket->print( http_headers() );

        # Передаём в process_request url, после чего, полученный ответ подготавливаем к выводу функцией http_respone
        my @data = process_request($url);
        if ($data[0] eq "yep" or $data[0] eq "nop") {$socket->print("<html>". $data[0]. "</html>");}
        elsif (@data) { $socket->print( http_respone(@data) ); }
        else { $socket->print( not_found() ); }

    	$socket->close;
    	undef( $socket );
    }
}
  
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