#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Audio::MPD;

our $VERSION = 2.0;
our $APP     = 'pimpd';
my  $DEBUG = 1;

my $confdir = "ENV{HOME}/.config/pimpd2";
if("$ENV{XDG_CONFIG_HOME}") {
  $confdir = "$ENV{XDG_CONFIG_HOME}/pimpd2";
}

eval {
  require "$confdir/pimpd2.conf" unless($DEBUG);
  require "./pimpd2.conf" if($DEBUG);
};
if($@) {
  print "$confdir/pimpd2.conf does not exist:\n\n";
  warn($@);
  exit(1);
}

# from config
our($host, $port, $pass);
our(%c);

my $mpd = undef;
if(defined($host)) { # remote
  $mpd = Audio::MPD->new(
    host  => $host,
    port  => $port,
    pass  => $pass,
  );
}
else {
  $mpd = Audio::MPD->new;
}

sub playlist {
  my $i = sprintf("%03d", 0);
  for($mpd->playlist->as_items) {
    my $title  = $_->title;
    my $artist = $_->artist;
    my $album  = $_->album;
    my $year   = $_->date;
    if($title eq $mpd->current->title and $artist eq $mpd->current->artist) {
      printf("$c{bold}$i▕ $c{grey}%4d$c{blue} %25.25s$c{darkblue}  %s$c{def}\n",
        $year,$artist, $title);
    }
    else {
      printf("$i▕ $c{grey}%4d$c{def} %25.25s▕ %s\n", $year,$artist, $title);

    }
    $i++;
  }
}


