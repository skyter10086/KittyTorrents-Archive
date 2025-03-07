unit class KittyTorrents::Archive:ver<0.0.1>:auth<github:skyter10086>:api<1>;

use HTML::Parser::XML;
use XML::Query;
use HTTP::Tinyish;
use DB::SQLite;
use Logger;
use URI;
use Terminal::Spinners;
=begin pod

=head1 NAME

KittyTorrents::Archive - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use KittyTorrents::Archive;

my $kt = KittyTorrents::Archive.new(
    :root<http://www.torkitty.net>
    :start(Date.new(2025,1,1))
    :end(Date.new(2025,1,31))
    :db-source<kt.db>
    :logfile<kt.log>
);
$kt.crawl();

=end code

=head1 DESCRIPTION

KittyTorrents::Archive is A simple web crawler for TorrentKitty.

=head1 AUTHOR

skyter10086 <skyter10086@aliyun.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 skyter10086

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

has Str $.root = 'http://www.torkitty.net';

has Date $.start;

has Date $.end;

has Str $.db-source = 'test.db';

has Str $.logfile = 'test.log';

#method query-torrents(Str $keyword --> List[Hash]) { ... }
method !db() {
    my $sqlite = DB::SQLite.new(filename => $!db-source);
    my $ddl = q:to/DDL/;
CREATE TABLE  if not exists Torrents
    (ID              TEXT    PRIMARY KEY     NOT NULL,
     TITLE           TEXT    NOT NULL,
     SUBJECT         TEXT    NOT NULL,
     LINK            TEXT    NOT NULL)
DDL
    $sqlite.execute($ddl); 
    self!log.warn('Connected DataBase.');
    return $sqlite.db;   
}

method !log() {
    return Logger.new(output => $!logfile.IO.open(:a));
}

method build-path() {
    my $base-url = $!root ~ '/archive';
    my Str @paths = ($!start ... $!end).map(*.gist).map( $base-url ~ '/' ~ *).list;    
}

method max-page(Str $url --> Int) { 
    my $ua = HTTP::Tinyish.new: :agent<Mozilla/5.0>;
    my $res = $ua.get: $url;
    my $content = $res.<content> if $res<success>;
    return 0 unless $res<success>;

    my $parser = HTML::Parser::XML.new;
    my $doc = $parser.parse($content);
    my $xq = XML::Query.new($doc);

    my Int $max-page = $xq('div .pagination').find('a').elements.map(*.attribs<href>.Int).max;
 }

method extract-magnet(Str $url) { 
    #my $ua = HTTP::Tiny.new: agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36 Edg/133.0.0.0', throw-exceptions => True; #, http-proxy => 'http://45.58.136.100:11715';
    my $uri = URI.new($url);
    my $root_ = $uri.scheme ~ '://' ~ $uri.host;
    my $ua = HTTP::Tinyish.new: :agent<Mozilla/5.0>;
    my $res = $ua.get: $url;
    return () unless $res<success> ;
    my $content = $res.<content> if $res<success>;

    my $parser = HTML::Parser::XML.new;
    my $doc = $parser.parse($content);
    my $xq = XML::Query.new($doc);   

    my @tags = $xq('[rel="information"]').find('a').elements;
    my @magnets;
    for @tags {
        my $title = $_.attribs<title>;
        my $sub = $root_ ~ $_.attribs<href>;
        my $id = $<tid>.Str if $sub ~~ /\/information\/$<tid>=(\S+)/;
        my $link = $xq('[rel="magnet"]').find('a').elements.grep(*.attribs<title> eq $title)[0].attribs<href>;
        @magnets.push: {id => $id, title => $title, subject => $sub, link => $link};
    }
    
    return @magnets;
 }

method crawl() {
    
    my $sth-insert = self!db.prepare('INSERT OR IGNORE INTO Torrents (id, title, subject, link) VALUES (?, ?, ?, ?)');
    my @paths = self.build-path;
    
    say "*" x 50;
    say "             Starting Work!!!";
    say '*' x 50;
    
  

    for  @paths -> $path  {
        #my $i = $_ - 1;
        #my $path = @paths[$i];
        
        my $max-page = self.max-page($path);
        next if $max-page == 0;
        say "{URI.new($path).path}:";
        my $hash-bar = Bar.new: type => 'hash', length => 50;
        $hash-bar.show: 0;
        
        my @pages = (1 .. $max-page).map: $path ~ '/' ~ *;
        
        for 1 .. @pages.elems {
            my $i = $_ - 1;
            my $page = @pages[$i];

            my $warn = "Extracting page: " ~ $page ~ " ... ";
            self!log.warn($warn);
            if my @mags = self.extract-magnet($page) {
                @mags.map: -> $m { 
                    $sth-insert.execute($m<id>, $m<title>, $m<subject>, $m<link>);
                    my $msg = "Torrent {$m<id>} -- {$m<title>} has been inserted.";
                    self!log.info($msg);
                }
            }

            my $percent = $_ / @pages.elems * 100; # calculate a percentage
            sleep 0.0002;                  # do iterative work here
            $hash-bar.show: $percent;
            
        }
        say();
        #my $percent = $_ / @paths.elems * 100; # calculate a percentage
        #sleep 0.0002;                  # do iterative work here
        #$hash-bar.show: $percent;
    }
    $sth-insert.finish;
    self!db.finish;
    say();
    say "    All Jobs Done! Good Luck!!!";
    #say '*' x 50;
}
