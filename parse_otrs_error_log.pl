#!/usr/bin/perl -w
use Modern::Perl;

my $amount; # Cчётчик

open FILEWORK, "<", "otrs_error.log" or die "Ошибка открытия файла otrs_error.log: $!\n";

while (<FILEWORK>) {
	if (/ .* Error .* Kernel::System::Ticket::TicketPermission /x) {
		if (/ .* Aug .* 6 .* 1 [0-7] : .* : .* 2017 .* /x) { $amount++; }
		elsif (/ .* Aug .* 6 .* 18:00:00 .* 2017 .* /x) { $amount++; }
	}
}
close FILEWORK;

say $amount;