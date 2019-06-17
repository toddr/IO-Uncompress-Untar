# NAME

IO::Uncompress::Untar - Pure-perl extension to read tar (and tgz and .tar.bz2 etc) files/buffers

# SYNOPSIS

    #!/usr/bin/perl -w
      
    use strict;
    use warnings;
    use IO::Uncompress::Untar qw($UntarError);

    my $u = new IO::Uncompress::Untar *STDIN or die "Cannot open";       # Prints the names of all the files in the tar / tgz / tar.bz2 / etc.
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

# DESCRIPTION

This module provides a minimal pure-Perl interface that allows the reading of tar files/buffers.
It maintains basic compatability/functionality of IO::Uncompress::Unzip

## EXPORT

None by default.

## Notes

Only these are implimented: new nextStream getHeaderInfo read

## new

    my $u = new IO::Uncompress::Untar *STDIN or die "Cannot open";

    my $u = new IO::Uncompress::Untar 'somefile.tgz' or die "Cannot open";

Uses AnyUncompress internally, so the stream or file can be a plain tar, or a gzip, bzip2, Z, or anything else compressed that AnyUncompress knows.

## read

Usage is

    $status = $z->read($buffer, $length)
    $status = $z->read($buffer, $length, $offset)

    $status = read($z, $buffer, $length)
    $status = read($z, $buffer, $length, $offset)

Attempt to read `$length` bytes of uncompressed data into `$buffer`.

## getHeaderInfo

Usage is

    $hdr  = $z->getHeaderInfo();
    @hdrs = $z->getHeaderInfo();

This method returns a hash reference (in scalar context) that contains information about the current file

## nextStream

Usage is

    my $status = $z->nextStream();

Skips to the next compressed data stream in the input file/buffer. If a new
compressed data stream is found, the eof marker will be cleared and `$.`
will be reset to 0.

Returns 1 if a new stream was found, 0 if none was found, and -1 if an
error was encountered.

# SEE ALSO

[Compress::Zlib](https://metacpan.org/pod/Compress::Zlib), [IO::Compress::Gzip](https://metacpan.org/pod/IO::Compress::Gzip), [IO::Uncompress::Gunzip](https://metacpan.org/pod/IO::Uncompress::Gunzip), [IO::Compress::Deflate](https://metacpan.org/pod/IO::Compress::Deflate), [IO::Uncompress::Inflate](https://metacpan.org/pod/IO::Uncompress::Inflate), [IO::Compress::RawDeflate](https://metacpan.org/pod/IO::Compress::RawDeflate), [IO::Uncompress::RawInflate](https://metacpan.org/pod/IO::Uncompress::RawInflate), [IO::Compress::Bzip2](https://metacpan.org/pod/IO::Compress::Bzip2), [IO::Uncompress::Bunzip2](https://metacpan.org/pod/IO::Uncompress::Bunzip2), [IO::Compress::Lzma](https://metacpan.org/pod/IO::Compress::Lzma), [IO::Uncompress::UnLzma](https://metacpan.org/pod/IO::Uncompress::UnLzma), [IO::Compress::Xz](https://metacpan.org/pod/IO::Compress::Xz), [IO::Uncompress::UnXz](https://metacpan.org/pod/IO::Uncompress::UnXz), [IO::Compress::Lzop](https://metacpan.org/pod/IO::Compress::Lzop), [IO::Uncompress::UnLzop](https://metacpan.org/pod/IO::Uncompress::UnLzop), [IO::Compress::Lzf](https://metacpan.org/pod/IO::Compress::Lzf), [IO::Uncompress::UnLzf](https://metacpan.org/pod/IO::Uncompress::UnLzf), [IO::Uncompress::AnyInflate](https://metacpan.org/pod/IO::Uncompress::AnyInflate), [IO::Uncompress::AnyUncompress](https://metacpan.org/pod/IO::Uncompress::AnyUncompress)

[IO::Compress::FAQ](https://metacpan.org/pod/IO::Compress::FAQ)

[File::GlobMapper](https://metacpan.org/pod/File::GlobMapper), [Archive::Zip](https://metacpan.org/pod/Archive::Zip),
[Archive::Tar](https://metacpan.org/pod/Archive::Tar),
[IO::Zlib](https://metacpan.org/pod/IO::Zlib)

# AUTHOR

This module was written by Chris Drake `cdrake@cpan.org`. 

# COPYRIGHT AND LICENSE

Copyright (c) 2019 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
