#!/usr/bin/perl -w

$c = 1;
while(<>) {
    if($c % 2 == 0) {
        print(substr($_, 1));
    }else{
        print $_;
    }
    $c++;
}

