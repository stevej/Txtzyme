#!/usr/bin/perl
# while sleep .5; do perl test.pl; done

use strict;

# Teensy (Unbuffered)

open T, "+>/dev/cu.usbmodem12341" or die($!);
select T; $| = 1;
select STDOUT; $| = 1;

# Txtzyme

sub putz { local $_; print T map "$_\n", @_ or die($!) }
sub getz { local $_; putz @_; $_ = <T>; $_ =~ s/\r?\n?$//; $_ }
putz "_ok_"; $_ = getz until /ok/;

# Bi-Color LED (between B0, B1)

sub red { putz "1bo" }
sub grn { putz "0b1o" }
sub off { putz "1b0obo" }
off;

# One-Wire Protocol (on pin F7)

sub rst { getz "7f0o480ui60uip420u" }
sub wr { putz $_[0] ? "7f0oi60u" : "7f0o60ui" }
sub w8 { my ($b) = @_; for (0..7) { wr($b&1); $b /= 2; } }
sub rd { getz "7f0oiip45u" }
sub r8 { my $b = 0; for (0..7) { $b |= (rd()<<$_) } return $b }

# DS18B20 Thermometer Functions

sub skip { w8 0xCC }
sub cnvt { w8 0x44 }
sub data { w8 0xBE }

# DS18B20 Thermometer Transactions

sub all_cnvt { rst; skip; cnvt; putz "750m" }
sub one_cnvt { rst; skip; cnvt; {} until rd }
sub one_data { rst; skip; data; my $c = r8; $c += 256 * r8 }

sub temp_c { all_cnvt; 0.0625 * one_data }
sub temp_f { 32 + 1.8 * temp_c }

printf "%3.5f c\n", temp_c;
