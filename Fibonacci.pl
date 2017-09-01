#!/usr/bin/perl -w
use Modern::Perl;
	
my $n = 50;
my @array = (0, 1);
for (my $i = 1; $i < $n; $i++) {
	push( @array, $array[$i] + $array[$i - 1] );
}

open(my $fh, '>', "output.txt") or die "Не удалось открыть output.txt - $!";
print $fh "@array";
close $fh;