#! /usr/bin/env perl
# -*- coding:utf-8 *-*

while (<>) {
    chomp $_;
    if ($_ =~ /\d*_(.*) - .*\.(.*)/) {
        printf "\"%s\"      \"%s.%s\"\n", $_, $1, $2
    }
}
