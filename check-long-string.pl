#!/usr/bin/env perl
# $v =~ // && grep ... vs for(...)
use strict;
use warnings;
use Benchmark ':all';
use Test::More 'no_plan';

my $Failed = 'Delivery failed, blacklisted by rbl.nyaan.jp';
my $RegExp = qr{(?>
     access[ ]denied[.][ ]ip[ ]name[ ]lookup[ ]failed
    |all[ ]mail[ ]servers[ ]must[ ]have[ ]a[ ]ptr[ ]record[ ]with[ ]a[ ]valid[ ]reverse[ ]dns[ ]entry
    |bad[ ]sender[ ]ip[ ]address
    |the[ ](?:email|domain|ip).+[ ]is[ ]blacklisted
    |this[ ]system[ ]will[ ]not[ ]accept[ ]messages[ ]from[ ]servers[/]devices[ ]with[ ]no[ ]reverse[ ]dns
    |too[ ]many[ ]spams[ ]from[ ]your[ ]ip  # free.fr
    |unresolvable[ ]relay[ ]host[ ]name
    |blacklisted[ ]by
    )
}x;
my $String = [
    'access denied. ip name lookup failed',
    'all mail servers must have a ptr record with a valid reverse dns entry',
    'bad sender ip address',
    ' is blacklisted',
    'this system will not accept messages from servers/devices with no reverse dns',
    'too many spams from your ip',  # free.fr
    'unresolvable relay host name',
    'blacklisted by',
];

sub regex {
    my $v = shift;
    return 1 if $v =~ $RegExp;
}

sub grep1 {
    my $v = shift;
    return 1 if grep { index($v, $_) > -1 } @$String;
}

sub grep2 {
    my $v = shift;
    return 1 if grep { rindex($v, $_) > -1 } @$String;
}

sub loop1 {
    my $v = shift;
    my $p = 0;
    for my $e ( @$String ) {
        next if index($v, $e) == -1;
        $p = 1;
        last;
    }
    return $p;
}

is regex($Failed), 1;
is grep1($Failed), 1;
is grep2($Failed), 1;
is loop1($Failed), 1;

printf("Running with Perl %s on %s\n%s\n", $^V, $^O, '-' x 80);
cmpthese(6e5, {
        '$v =~ //'        => sub { regex($Failed) },
        'grep { index }'  => sub { grep1($Failed) },
        'grep { rindex }' => sub { grep2($Failed) },
        'for { index }'   => sub { loop1($Failed) },
    }
);

eval { require Devel::Size };
unless( $@ ) {
    printf("\n");
    printf("%s %6d bytes\n", 'qr{...}', Devel::Size::total_size($RegExp));
    printf("%s %6d bytes\n", '[a,b,c]', Devel::Size::total_size($String));
}

__END__

Running with Perl v5.18.2 on darwin
--------------------------------------------------------------------------------
                    Rate   $v =~ // for { index } grep { index } grep { rindex }
$v =~ //        382166/s         --          -39%           -48%            -48%
for { index }   625000/s        64%            --           -15%            -15%
grep { index }  731707/s        91%           17%             --             -0%
grep { rindex } 731707/s        91%           17%             0%              --

Running with Perl v5.22.1 on darwin
--------------------------------------------------------------------------------
                    Rate   $v =~ // for { index } grep { index } grep { rindex }
$v =~ //        447761/s         --          -33%           -45%            -49%
for { index }   666667/s        49%            --           -18%            -23%
grep { index }  810811/s        81%           22%             --             -7%
grep { rindex } 869565/s        94%           30%             7%              --

Running with Perl v5.28.1 on darwin
--------------------------------------------------------------------------------
                     Rate  $v =~ // for { index } grep { index } grep { rindex }
$v =~ //         500000/s        --          -44%           -50%            -57%
for { index }    895522/s       79%            --           -10%            -22%
grep { index }  1000000/s      100%           12%             --            -13%
grep { rindex } 1153846/s      131%           29%            15%              --

