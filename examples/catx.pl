#!/usr/bin/perl -w

# Walks through a file system recursing into subfolders and zip and tar files to print out a listing of all the files found in there.
# NB: Uses a modified Stream.pm with the "die" statements removed.

# See also https://github.com/detly/arkfind

our $VERSION='0.20190623';	# Please use format: major_revision.YYYYMMDD[hh24mi]
use strict;
use Date::Calc qw(Date_to_Time);
use IO::Uncompress::Unzip qw($UnzipError);
use IO::Uncompress::Untar qw($UntarError);
use Digest::MD5 qw(md5_hex);	# We'll print the last 60 bits (15 hex bytes) of this so we can unique-ident files without wasting too much space
use Getopt::Long;       # Commandline argument parsing
use Archive::Tar::Stream 0.03; $Archive::Tar::Stream::NODIE=1;
my %arg; &GetOptions(	'norecurse'		=> \$arg{'norecurse'},
			'nocol'			=> \$arg{'nocol'},		# no colours
			'tag=s'			=> \$arg{'tag'},		# no colours
           ) or die "see pod in file for usage";
my ($norm,$red,$grn,$yel,$nav,$blu,$save,$rest,$clr,$prp,$wht)=("\033[0m","\033[31;1m","\033[32;1m","\033[33;1m","\033[34;1m","\033[36;1m","\033[s","\033[u","\033[K","\033[35;1m","\033[37;1m"); ($norm,$red,$grn,$yel,$nav,$blu,$save,$rest,$clr,$prp,$wht)=() if($arg{'nocol'}); my($col)=$norm;        # default col


my $adder = new addfile("mycat.txt",$arg{'tag'});
my $from=$ARGV[0]; $from="." unless($from);
my $spidy = new spiderfs('from'=>$from,'adder'=>$adder,'recurse'=>1);
$spidy->go();
print "end.\n";
exit(0);


# Go through a zip file
package spiderzip;

  sub new {
    my $class = shift;        # Get the request class name
    if(!@::SZFH) {
      no warnings;
      $::SZFHC=0;
      @::SZFH=(\*SZFH0,\*SZFH1,\*SZFH2,\*SZFH3,\*SZFH4,\*SZFH5,\*SZFH6,\*SZFH7,\*SZFH8,\*SZFH9,\*SZFH10,\*SZFH11,\*SZFH12,\*SZFH13,\*SZFH14,\*SZFH15,\*SZFH16,\*SZFH17,\*SZFH18,\*SZFH19,\*SZFH20,\*SZFH21,\*SZFH22,\*SZFH23,\*SZFH24,\*SZFH25,\*SZFH26,\*SZFH27,\*SZFH28,\*SZFH29,\*SZFH30,\*SZFH31,\*SZFH32,\*SZFH33,\*SZFH34,\*SZFH35,\*SZFH36,\*SZFH37,\*SZFH38,\*SZFH39,\*SZFH40,\*SZFH41,\*SZFH42,\*SZFH43,\*SZFH44,\*SZFH45,\*SZFH46,\*SZFH47,\*SZFH48,\*SZFH49,\*SZFH50,\*SZFH51,\*SZFH52,\*SZFH53,\*SZFH54,\*SZFH55,\*SZFH56,\*SZFH57,\*SZFH58,\*SZFH59,\*SZFH60,\*SZFH61,\*SZFH62,\*SZFH63,\*SZFH64,\*SZFH65,\*SZFH66,\*SZFH67,\*SZFH68,\*SZFH69,\*SZFH70,\*SZFH71,\*SZFH72,\*SZFH73,\*SZFH74,\*SZFH75,\*SZFH76,\*SZFH77,\*SZFH78,\*SZFH79,\*SZFH80,\*SZFH81,\*SZFH82,\*SZFH83,\*SZFH84,\*SZFH85,\*SZFH86,\*SZFH87,\*SZFH88,\*SZFH89,\*SZFH90,\*SZFH91,\*SZFH92,\*SZFH93,\*SZFH94,\*SZFH95,\*SZFH96,\*SZFH97,\*SZFH98,\*SZFH99);	# Stupid globs can't easily be local...;
      @::SZFHC=(); # 1 means in-use
      use warnings;
    }
    my %this=@_; my $this=\%this;
    if($^O =~/Win32/i) {$::slash="\\"} else {$::slash='/';}
    if(substr($this{'from'},0,1) eq '*') { # Guts of something (a file handle)
      $this{'root'}=$this{'parent'} . " $::slash ";
    } else {	# A zip file
      $this{'root'}=$this{'from'} . " $::slash ";
    }
    #die "Start folder missing" unless((defined $this{'from'})&&(-f $this{'from'}));
    die "Add folder func missing" unless(ref($this{'adder'}));
    bless $this,$class;       # Connect the hash to the package Cocoa.
    return $this;     # Return the reference to the hash.
  } # new

  sub getFH {
    my $i=$#::SZFH;
    while(($i--)&&($::SZFHC[$::SZFHC])) {$::SZFHC=($::SZFHC+1 % $#::SZFH); }; # Find an unused one
    die "Out of handles" if($i<1);
    $::SZFHC[$::SZFHC]++;
    return($::SZFH[$::SZFHC]);
  } # getFH

  sub go {
    my $fsobj=shift;
    my @subdir;
#warn "Processing $fsobj->{'from'} ok";
    my $u;
    if( $fsobj->{'tar'} ) {
      $u = new IO::Uncompress::Untar $fsobj->{'from'} or warn "Cannot open $fsobj->{'from'}";
    } else { # Zip
      $u = new IO::Uncompress::Unzip $fsobj->{'from'} or warn "Cannot open $fsobj->{'from'} / $fsobj->{'root'} / $fsobj->{'parent'} $IO::Uncompress::Unzip::UnzipError";
    }
    return if(!defined $u);

    my $status;
    for ($status = 1; $status > 0; $status = $u->nextStream()) {
      my $hdr = $u->getHeaderInfo();
      my $fn = $hdr->{Name};
#warn "fn=$fn";      
      last if(!defined $fn);
      #use Data::Dumper; warn "Processing member $fn ok:" .  Data::Dumper->Dump([$hdr],["\$hdr"]);
      
      #join("^",%{$hdr});
      #warn "Processing member $fn ok:" . join("^", @{$hdr->{UncompressedLength}});
      my @sz= ref $hdr->{UncompressedLength} ? @{$hdr->{UncompressedLength}} : ($hdr->{UncompressedLength});
      if( $hdr->{'Stream'} ) { $sz[0]='?'; }

      #foreach my $k(keys %{$hdr}) {
      #	next if($k eq 'ExtraFieldRaw'); # binary
      #	next if($k eq 'Header'); # binary
      #	#warn "$k\t= " . $hdr->{$k} . "\n"; # MethodID	= 8 / HeaderLength	= 54 / Stream	= 1 / ExtraField	= ARRAY(0x7fcf1b034038) / MethodName	= Deflated / UncompressedLength	= U64=ARRAY(0x7fcf1b033a50) / Type	= zip / CRC32	= 0 / CompressedLength	= U64=ARRAY(0x7fcf1b033a08) / FingerprintLength	= 4 / Time	= 1554280874 / Name	= META-INF/MANIFEST.MF / Zip64	= 0 / TrailerLength	= 16
      #}
 
      my $buff;
      my $rstatus=$u->read($buff,4); # Check for magic of this file
#warn "magic($fn)  u=$u  fso=$fsobj->{'from'}  r=$rstatus  magic=" . unpack("H*",$buff);      
      if((defined $buff)&&($::zipmagic{$buff})&&( ($sz[0] eq '?') || ($sz[0]>22))) {	# Spider this if it's a (non-empty) ZIP file
	my $FH2=&getFH(); my $FHNUM=$::SZFHC;
	tie *{$FH2}, 'ArcHandle', $u,$buff,$::SZFHC-1;	# Create a file handle which can read from this compressed data
	my $ctx = Digest::MD5->new;
	my $spidy = new spiderzip('from'=>*{$FH2},'parent'=>"$fsobj->{'root'} $fn",'adder'=>$fsobj->{'adder'},'recurse'=>1,'dat'=>$buff,'pszfhc'=>$::SZFHC-1,'md5'=>$ctx); $spidy->go(); close(*{$FH2}); $::SZFHC[$FHNUM]--;
      } elsif($fn=~/\.(tar|tgz|tar\.gz|tar\.bz2|tar\.xz|tar\.z)$/i) {	# A tar file
	my $FH2=&getFH(); my $FHNUM=$::SZFHC;
	#my $FH2=$::SZFH[$::SZFHC++];
	tie *{$FH2}, 'ArcHandle', $u,$buff,$::SZFHC-1;	# Create a file handle which can read from this compressed data
#warn "Tied FH=" . $FH2;
	my $ctx = Digest::MD5->new;
	my $spidy = new spiderzip('tar'=>1,'from'=>*{$FH2},'parent'=>"$fsobj->{'root'} $fn",'adder'=>$fsobj->{'adder'},'recurse'=>1,'dat'=>$buff,'pszfhc'=>$::SZFHC-1,'md5'=>$ctx); $spidy->go(); close(*{$FH2});  $::SZFHC[$FHNUM]--;

	#local *FH;
	#tie *FH, 'ArcHandle', $u,$buff;	# Create a file handle which can read from this compressed data
	#warn "Tied FH=" . *FH;
	#my $spidy = new spiderzip('tar'=>1,'from'=>*FH,'parent'=>"$fsobj->{'root'} $fn",'adder'=>$fsobj->{'adder'},'recurse'=>1,'dat'=>$buff); $spidy->go();
      }

      if(  $hdr->{'Stream'} ) {
        my $size=length($buff);
        while (($status = $u->read($buff)) > 0) {	#  $status = $z->read($buffer, $length)
  	  $size+=length($buff); # Do something here
        }
	$sz[0]=$size;
      }
      my @stat=(0,1,2,3,4,5,6,$sz[0] ,8,$hdr->{Time});
      $fsobj->{'adder'}->add($fsobj->{'root'},$fn,\@stat);
      last if $status < 0;
    } # for status
 
    warn "Error '$IO::Uncompress::Unzip::UnzipError' / $! processing $fsobj->{'from'} / $fsobj->{'root'} / $fsobj->{'parent'}" if $status < 0 ;

    $u->close();
  } # go

1; # spiderzip


# Go through a file system
package spiderfs;

  sub new {
    my $class = shift;        # Get the request class name
    my %this=@_; my $this=\%this;
    if($^O =~/Win32/i) {$::slash="\\"} else {$::slash='/';}
    $this{'root'}=''; # unless($this{'root'});
    unless((defined $this{'from'})&&(-d $this{'from'})) {
      warn "Start folder $this{'from'} missing or not a directory";
      return undef;
    }
    die "Add folder func missing" unless(ref($this{'adder'}));
    %::zipmagic=("PK\x03\x04"=>'zip',"PK\x05\x06"=>'zip',"PK\x07\x08"=>'zip');
    $this{'from'}.=$::slash unless(substr($this{'from'},-1) eq $::slash);
    bless $this,$class;       # Connect the hash to the package Cocoa.
    return $this;     # Return the reference to the hash.
  } # new

  sub go {
    my $fsobj=shift;
    my @subdir; my @subdir2;
    if(opendir(my $THISDIR,$fsobj->{'from'})) {
      while(my $file=readdir $THISDIR) {
	my $archive=0; # don't double-read archive files when doing the MD5
	my $md5;
	next if(($file eq '.')||($file eq '..'));
	my $fn=$fsobj->{'from'} . $file;
	if(-l $fn) {	# symlink
	  my @stat=lstat($fn);     # stats the sym, not the target # 2=type+mode, 6=rdev, 7=size, 9=mtime
=for code
	   0 dev      device number of filesystem
	     1 ino      inode number
	       2 mode     file mode  (type and permissions)
	         3 nlink    number of (hard) links to the file
		   4 uid      numeric user ID of file's owner
		     5 gid      numeric group ID of file's owner
		       6 rdev     the device identifier (special files only)
		         7 size     total size of file, in bytes
			   8 atime    last access time in seconds since the epoch
			     9 mtime    last modify time in seconds since the epoch
			      10 ctime    inode change time in seconds since the epoch (*)
			       11 blksize  preferred I/O size in bytes for interacting with the file (may vary from file to file)
				 12 blocks   actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)
=cut
	} elsif(-f $fn) {
	  my @stat=stat($fn);       # stats the target # 2=type+mode, 6=rdev, 7=size, 9=mtime
	  my($mode)=$stat[2]>>12;   # 8=regular, 10=symlink, 4=dir

	  if($stat[7]>4) {		# Is the file big enough to be an archive?
	    if(open(MAGIC,'<',$fn)) {
	      binmode(MAGIC);
	      my $magic;sysread(MAGIC,$magic,4,0);	# Read first 4 bytes
	      close(MAGIC);
	      if(($::zipmagic{$magic})&&($stat[7]>22)){	# Spider this if it's a ZIP file
	        push @subdir,$fn;
		$archive=1;
	      }
	      if( $fn=~/\.(tar|tgz|tar\.gz|tar\.bz2|tar\.xz|tar\.z|not\.exe)$/i) {	# Spider tar files too
	        push @subdir2,$fn;
		$archive=1;
	      }
	    } # has magic
	  } # big enough to be an archive
	  if(!$archive) {
	    my $ctx = Digest::MD5->new; my($IN); if(!open($IN,'<' , $fn)) { warn "Cannot read $fn: $!"; $md5='00000000000000000000000000000000'; }
	    else { binmode($IN); eval('$ctx->addfile($IN);'); close($IN); $md5=$ctx->hexdigest; }
	  } # archive
	  $fsobj->{'adder'}->add($fsobj->{'root'},$fn,\@stat,$md5);
	  #die join("^",@stat);	# file=./out.xlsx 16777220^7774935^33261^1^501^20^0^72885^1550610572^1502977837^1502977837^4096^144 at catx.pl line 37.
	  			# -rwxr-xr-x  1 cnd  staff  72885 17 Aug  2017 out.xlsx*
	  			# pdate 1550610572 1502977837   2019/02/19 21:09.32  2017/08/17 13:50.37
				#
	} elsif(-d $fn) {
	  my @stat=stat($fn);       # stats the target # 2=type+mode, 6=rdev, 7=size, 9=mtime
	  my($mode)=$stat[2]>>12;   # 8=regular, 10=symlink, 4=dir
	  $fn.= $::slash unless(substr($fn,-1) eq $::slash);
          push @subdir,$fn if($fsobj->{'recurse'}); # if(($mode==4)); # &&(!-l $fn));	# recurse
	  $fsobj->{'adder'}->add($fsobj->{'root'},$fn,\@stat);
	} else {
	  # Skip non files
	  warn "skipped $fn";
	}
      } # while
      close($THISDIR);
      foreach my $sub(@subdir) {
	next if(($sub eq '/proc/')||($sub eq '/sys/'));
	my $ctx = Digest::MD5->new;
        if(substr($sub,-1) eq $::slash) {	# File system object
	  next unless((defined $sub)&&(-d $sub));
	  my $spidy = new spiderfs('from'=>$sub,'adder'=>$fsobj->{'adder'},'recurse'=>1,'md5'=>$ctx); if(ref($spidy)){ $spidy->go() } else { warn "spiderfs err '$sub' $!"; }
	} else {				# zip file
	  my $spidy = new spiderzip('from'=>$sub,'adder'=>$fsobj->{'adder'},'recurse'=>1,'md5'=>$ctx); if(ref($spidy)){ $spidy->go() } else { warn "spiderzip err '$sub' $!"; }
	}
      }
      foreach my $sub(@subdir2) {	# Tars
	my $ctx = Digest::MD5->new;
	my $spidy = new spiderzip('tar'=>1,'from'=>$sub,'adder'=>$fsobj->{'adder'},'recurse'=>1,'md5'=>$ctx); if(ref($spidy)){ $spidy->go() } else { warn "spiderzip(tar) err '$sub' $!"; }
      }

    } else {
      warn "Can't open '$fsobj->{'from'}'";
    }
  } # go

1; # spiderfs

# Output file metadata
package addfile;
  sub new {
    my $class = shift;        # Get the request class name
    my $outfile = shift;	# Where to write to
    my $tag = shift;
    print "   Date      Time        Size_Bytes      md5sum_60lsbt \tpath/archive / fielname.ext\n";
    print "========== ======== =================== ===============\t===========================\n"; 
    print &dateme(undef,time()) . "                    SpiderFS       \t$tag\n" if($tag);
    if($tag){$tag.=' ';}else{$tag='';}
    my $this = {'outfile'=>$outfile,'tag'=>$tag};
    bless $this,$class;       # Connect the hash to the package Cocoa.

    return $this;     # Return the reference to the hash.
  } # new
  sub add {
    my($o)=shift;
    my $root=shift;
    my $fn=shift;
    my $pstat=shift;
    my $md5=shift;
    #warn join("^",@{$pstat});
    #print "$root$fn\t$$pstat[7]\t${\$o->dateme($pstat->[9])}\n";
    #    print $o->dateme($pstat->[9]) . " ";
    #    print sprintf("%19s", reverse(join(",",unpack("(A3)*", reverse int($$pstat[7]))))."") . "\t";
    #    print "$root$fn\n";

    #print STDERR $o->dateme($pstat->[9]) . sprintf(" %19s", reverse(join(",",unpack("(A3)*", reverse int($$pstat[7]))))."") . "\t$root$fn\n";
    $md5='                                ' unless(defined $md5);
    $md5=substr($md5,14,15);
    $root=$o->{'tag'} . $root;
    if($$pstat[7] =~/^\d+$/) {
      print $o->dateme($pstat->[9]) . sprintf(" %19s", reverse(join(",",unpack("(A3)*", reverse int($$pstat[7]))))."") . " $md5\t$root$fn\n";
    } else {
      print $o->dateme($pstat->[9]) . sprintf(" %19s", $$pstat[7]) . " $md5\t$root$fn\n";
    }


  } # add
  sub dateme {
    my($o)=shift;
    my($time)=@_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
    return sprintf("%04d/%02d/%02d %02d:%02d.%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
  } # dateme
1; # addfile


# Read data out of an archive file as if it was an actual file
package ArcHandle;
  require Tie::Handle;
  #@ISA = qw(Tie::Handle);
  sub EOF { my $obj=shift; warn "EOF"; return $obj->{ptr}>length($obj->{dat}); }
  sub CLOSE { } # { warn "CLOSE called. "  . $_[0] . join("^",%{$_[0]}) ;  }
  sub DESTROY { } # { warn "DESTROY " . $_[0] . join("^",%{$_[0]}) ; }
  sub READ {			# READ this, scalar, length, offset: Read length bytes of data into scalar starting at offset.
    my $obj=shift;
    #warn join("^",@_);		# e.g. 4^0
    my $l=$_[1];
    die "Seek not supported" if($_[2]);
    if(length($obj->{dat})) {
      if($l>length($obj->{dat})){
        my $u=$obj->{obj};
	my $tmp;
        $u->read($tmp,$l-length($obj->{dat}));
	$obj->{dat}.=$tmp;
	#warn "grr l=$l";
      }
      die "read($l) from ".length($obj->{dat})." Not implimented" if($l>length($obj->{dat})); # if you need this, read $l-len(dat) from buf, then add dat on front to return
      $_[0]=substr($obj->{dat},$obj->{ptr},$l); $obj->{dat}=substr($obj->{dat},$l); $l=0;
    }
    if($l) {
      my $u=$obj->{obj};
      return $u->read($_[0],$l);
    }
    return length($_[0]);
  }
  sub BINMODE {  }
  #sub TIESCALAR { return TIEHANDLE @_; }
  sub TIEHANDLE { 
    my $this={};
    #warn join("^",@_);	#NewHandle^foomanchew at iozipplay.pl line 57.
    $this->{'szfhc'}=$_[3];
    $this->{dat}=$_[2];	# the 4byte file magic
    $this->{obj}=$_[1];	# Where to read from (*FH filehandle)
    $this->{ptr}=0;
    #warn $r; my $foo=substr($this->{dat},0,4); warn $foo;
    bless $this;
    return $this;
  }	# Overrides inherited method
1;



# Return the md5 checksum of the provided file
sub md5 {
  my($file,$size)=@_;
  my $ctx = Digest::MD5->new;
  my($IN);
  $file=$1 if($file=~/'(.*)'/); # $file=~s/ /\\ /g;
  if(!open($IN,'<' , $file)) { warn "Cannot read $file: $!"; return '00000000000000000000000000000000'; }
  binmode($IN);
  #$ctx -> reset;
  my $md5=$ctx->addfile($IN);
  close($IN);
  my($ret)=$ctx->hexdigest;
  
  if(($size>0)&&($ret eq 'd41d8cd98f00b204e9800998ecf8427e')){ warn "md5($file) failed!"; return '00000000000000000000000000000000'; }
  return $ret;
} # md5
