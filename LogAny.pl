#!/usr/bin/perl -w
use Modern::Perl;
use Log::Any qw($log);
use Log::Any::Adapter ('Stdout');

$log->debug("Дебаг");
$log->info("Информация");
$log->warn("Предупреждение");
$log->error("Ошибка");

