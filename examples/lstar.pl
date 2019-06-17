#!/usr/bin/perl -w

use strict;
use warnings;
use IO::Uncompress::Untar qw($UntarError);

my $u = new IO::Uncompress::Untar *STDIN or die "Cannot open $IO::Uncompress::Untar::UntarError";	# Prints the names of all the files in the tar / tgz / tar.bz2 / etc.
my $status;

for ($status = 1; $status > 0; $status = $u->nextStream()) {
  my $hdr = $u->getHeaderInfo();
  my $fn = $hdr->{Name};
  last if(!defined $fn);
  my @sz= ref $hdr->{UncompressedLength} ? @{$hdr->{UncompressedLength}} : ($hdr->{UncompressedLength});

  my $buff;
  while (($status = $u->read($buff)) > 0) {
    # Do something here
  }
  print "$hdr->{Time}\t$sz[0]\t$fn\n"; 
  last if $status < 0;
} # for status
