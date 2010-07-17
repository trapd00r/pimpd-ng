#!/usr/bin/perl
use strict;
use Carp;
use Getopt::Long;
use Audio::MPD;

our $VERSION = 2.0;
our $APP     = 'pimpd-ng';
my  $DEBUG = 1;

my $confdir = "ENV{HOME}/.config/pimpd-ng";
if("$ENV{XDG_CONFIG_HOME}") {
  $confdir = "$ENV{XDG_CONFIG_HOME}/pimpd-ng";
}

eval {
  require "$confdir/pimpd-ng.conf" unless($DEBUG);
  require "./pimpd-ng.conf" if($DEBUG);
};
if($@) {
  print "$confdir/pimpd-ng.conf does not exist:\n\n";
  warn($@);
  exit(1);
}

# from config
our($host, $port, $pass);
our(%c); # colors and attributes
our($status_style);

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

# options
our($opt_oneline);
our($playlist_dir, $favlist_format); # from config
GetOptions(
  'playlist'    => \&playlist,
  'current|np'  => \&current,
  'clear'       => sub { $mpd->playlist->clear },
  'albums'      => sub { print "$_\n" for(sort{$a cmp $b} albums_by_artist()) },
  'fav'         => sub { favlist($favlist_format) },
);

sub favlist {
  # genre, date, custom string?
  my $type = shift;
  return() if(!defined($type));

  #my $favlist_format = undef;
  my $genre = $mpd->current->genre;

  if($type eq 'genre') {
    $favlist_format = "$genre";
  }
  elsif($type eq 'date') {
    $favlist_format = time();
  }
  elsif($type eq 'both') {
    $favlist_format = $genre . time();
  }

  open(my $fh, '>>', "$playlist_dir/$favlist_format.m3u")
    or carp("Cant append to $playlist_dir/$favlist_format: $!");
  print $fh $mpd->current->file, "\n";
  close($fh);

}


sub albums_by_artist {
  my $artist = shift // $mpd->current->artist;
  return if(!defined($artist));
  return($mpd->collection->albums_by_artist($artist));
}

sub playlist {
  my $i = sprintf("%03d", 0);
  for($mpd->playlist->as_items) {
    my $title  = $_->title;
    my $artist = $_->artist;
    my $album  = $_->album;
    my $year   = $_->date;
    my $file   = $_->file;
    if($file eq $mpd->current->file) {
      printf("$c{bold}$i▕ $c{grey}%4d$c{blue} %25.25s$c{darkblue}  %s$c{def}\n",
        $year,$artist, $title);
    }
    else {
      printf("$i▕ $c{grey}%4d$c{def} %25.25s▕ %s\n", $year,$artist, $title);

    }
    $i++;
  }
}

sub current {
  my $artist = $mpd->current->artist // 'undef';
  my $album  = $mpd->current->album  // 'undef';
  my $title  = $mpd->current->title  // 'undef';
  my $year   = $mpd->current->date   // 0000;

  if($opt_oneline or $status_style eq 'oneline') {
    # $opt_oneline from --no-color, $current_style from config.
    # Show info on one line
    printf("%s - %s (%s [%d])", $artist, $title, $album, $year);
  }
  else {
    print "All info.\n";
  }
}

