#!/usr/bin/perl -w
use Modern::Perl;
use JSON::XS;

my @json_file;
open FILEWORK, "<", "error.json" or die "Ошибка открытия файла error.json: $!\n";
$/ = undef;
@json_file = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
close FILEWORK;

my $array_errors = $json_file[0] -> {errors};

foreach my $book (@$array_errors) {
	print $book -> {"status"}. " : ". $book -> {"detail"}. "\n";
}