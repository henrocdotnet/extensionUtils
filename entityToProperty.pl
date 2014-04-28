#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
#use Encode;
use File::Find;

my $cwd = getcwd();
my $tempFile = 'my_new.properties';

my %map = (
	"gblite.confirm.title" => "GBL_HistoryConfirmTitle",
	"gblite.confirm.label.usure" => "GBL_HistoryConfirmPrompt"
);

print "Scanning locale folders...\n\n";
find(\&wanted, $cwd);

sub wanted
{
	return if ! m/\.dtd$/;
	
	my $id = $File::Find::dir;
	$id =~ s!^.+/(.+)$!$1!;
	
	printf("%5s\n", $id);
	
	my @dtds = <*.dtd>;
	foreach my $f (@dtds)
	{
		open my $in, '<:encoding(UTF-8)', $f or die "Cannot open $f: $!";
		open my $out, '>:encoding(UTF-8)', $tempFile or die "Cannot open $tempFile: $!";
		
		my $skip = 0;
		while (<$in>)
		{
			foreach my $k (keys %map)
			{
				if(m/$k/)
				{
					my ($value) = (m/"([^"]+)"/);
					print $out $map{$k} . "=$value\n";
					last;
				}
			}
		}
		close $out;
		close $in;
	}
}
