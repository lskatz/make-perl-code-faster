#!/usr/bin/env perl

use strict;
use warnings;
use Benchmark ':all';
use Test::More 'no_plan';
use Data::Dumper;

my $k = 21; # kmer length

# Create random DNA string
my @DNA   = "";
my @NT    = qw(A C G T);
my $numNts= scalar(@NT);
for(1..300){
  push(@DNA, $NT[int(rand($numNts))]);
}
my $DNA = join("", @DNA);
note "DNA string is:$DNA";

my $expected = kmersBySubstr($DNA, $k);

# Sanity checks to check first and last nt
# Because of big data.
is(substr($$expected[0],0,1), substr($DNA,0,1), "First nt of DNA is first nt of first kmer");
is(substr($$expected[-1],-1,1), substr($DNA,-1,1), "Last nt of DNA is last nt of last kmer");

is_deeply(kmersBySubstr($DNA, $k), $expected, "kmersBySubstr");
is_deeply(unpackKmers($DNA, $k), $expected, "unpackKmers");
is_deeply(regexSlidingWindow($DNA, $k), $expected, "regexSlidingWindow");
is_deeply(kmersByMap($DNA, $k), $expected, "kmersByMap");
is_deeply(kmersBySplittingAndJoining($DNA, $k), $expected, "kmersBySplittingAndJoining");
is_deeply(kmersByJoining(\@DNA, $k), $expected, "kmersByJoining");
is_deeply(kmersByJoiningWithMap(\@DNA, $k), $expected, "kmersByJoiningWithMap");

sub kmersBySubstr{
  my($DNA, $k) = @_;
  my @kmer;
  my $numKmers = length($DNA) - $k + 1;
  for(my $i=0; $i < $numKmers; $i++){
    push(@kmer,
      substr($DNA, $i, $k)
    );
  }
  return \@kmer;
}

sub unpackKmers{
  my($DNA, $k) = @_;
  my @kmer;
  my $numKmers = length($DNA) - $k + 1;
  for(my $i=0; $i < $numKmers; $i++){
    push(@kmer,
      unpack("x$i a$k", $DNA)
    );
  }
  return \@kmer;
}

sub regexSlidingWindow{
  my($DNA, $k) = @_;
  my @kmer;

  my $re = qr/(?=(.{$k}))/;
  while($DNA =~ /$re/g){
    push(@kmer, $1);
  }
  return \@kmer;
}


sub kmersByJoiningWithMap{
  my($DNAARR, $k) = @_;

  my $numKmers = scalar(@$DNAARR) - $k + 1;

  my @kmer = map{
    join("", @$DNAARR[$_..$_+$k-1]);
  } (1..$numKmers-1);
  return \@kmer;
}

sub kmersByJoining{
  my($DNAARR, $k) = @_;

  my @kmer;
  my $numKmers = scalar(@$DNAARR) - $k + 1;
  for(my $i=1; $i < $numKmers; $i++){
    push(@kmer, join("", @$DNAARR[$i..$i+$k-1]));
  }
  return \@kmer;
}

sub kmersBySplittingAndJoining{
  my($DNA, $k) = @_;

  my @kmer;
  my @nt = split(//, $DNA);
  my $numKmers = length($DNA) - $k + 1;
  for(my $i=0; $i < $numKmers; $i++){
    push(@kmer, join("", @nt[$i..$i+$k-1]));
  }
  return \@kmer;
}

sub kmersByMap{
  my($DNA, $k) = @_;

  my $numKmers = length($DNA) - $k + 1;
  my @kmer = map{
    substr($DNA, $_, $k)
  } (0..$numKmers-1);

  return \@kmer;
}

printf("Running with Perl %s on %s\n%s\n", $^V, $^O, '-' x 80);
cmpthese(1e4, {
        'kmersBySubstr'              => sub { kmersBySubstr($DNA, $k) },
        'unpackKmers'                => sub { unpackKmers($DNA, $k) },
        'regexSlidingWindow'         => sub { regexSlidingWindow($DNA,$k) },
        'kmersByMap'                 => sub { kmersByMap($DNA, $k) },
        'kmersBySplittingAndJoining' => sub { kmersBySplittingAndJoining($DNA, $k) },
        'kmersByJoining'             => sub { kmersByJoining(\@DNA, $k) },
        'kmersByJoiningWithMap'      => sub { kmersByJoiningWithMap(\@DNA, $k) },
    }
);

__END__

