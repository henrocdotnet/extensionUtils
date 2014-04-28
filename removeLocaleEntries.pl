#!/usr/bin/perl
use strict;
use warnings;

use Cwd;
use Encode;
use File::Find;

my $cwd = getcwd();
my $tempFile = 'cleaned_locale.dtd';

my @toRemove = (
	"gblite.confirm.title",
	"gblite.confirm.label.usure",
	"gblite.confirm.label.yes",
	"gblite.confirm.ak.yes",
	"gblite.confirm.label.no",
	"gblite.confirm.ak.no"
);

print "Scanning locale folders...\n\n";
find(\&wanted, $cwd);

sub wanted
{
	return if ! m/\.dtd$/;
	
	my $id = $File::Find::dir;
	$id =~ s!^.+/(.+)$!$1!;
	
	printf("%5s", $id);
	
	my @dtds = <*.dtd>;
	foreach my $f (@dtds)
	{
		open my $in, '<:encoding(UTF-8)', $f or die "Cannot open $f: $!";
		open my $out, '>:encoding(UTF-8)', $tempFile or die "Cannot open $tempFile: $!";
		
		my $removed = 0;
		my $skip = 0;
		while (<$in>)
		{
			$skip = 0;
			
			foreach my $match (@toRemove)
			{
				if(m/$match/)
				{
					$removed++;
					$skip = 1;
					last;
				}
			}
			
			next if $skip == 1;
			
			print $out $_;
		}
		close $out;
		close $in;
		
		if ($removed > 0)
		{
			printf("  --  Removed %d %s\n", $removed, $removed == 1 ? 'entity' : 'entities');
			unlink $f or die "Unable to remove $f: $!";
			rename $tempFile, $f;
		}
		else
		{
			print "  --  Nothing to do!\n";
		}
	}
}
