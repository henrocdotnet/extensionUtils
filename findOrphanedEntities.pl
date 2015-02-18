#!/usr/bin/perl
use strict;
use warnings;

our $VERSION = "1.01";

use Cwd;
use File::Find;
use Getopt::Long;

my $masterLocale = 'en-US';

GetOptions(
	"master=s" => \$masterLocale,
	"help" => sub { usage(); exit 0; }
);

my $target = shift;
if (!$target)
{
	$target = getcwd();
}
else
{
	chdir $target or die "Unable to change to $target: $!";
}

my %ids = ();
my %unknown = ();

print "\nFind Orphaned Entities v$VERSION\n\n";
print "Parameters:\n";
print " - Master locale: $masterLocale\n";

print "\nScanning for master locale entities...\n";
find(\&scanMaster, $target);

print "\nScanning XUL files for entities...\n";
find(\&scanForIds, $target);

print "\nPotential orphans found:\n";
foreach (sort keys %ids)
{
	if ($ids{$_} == 0)
	{
		print " - $_\n";
	}
}

print "\nUnknown entities found:\n";
foreach (sort keys %unknown)
{
	print " - $_: $unknown{$_}\n";
}

sub scanForIds
{
	return if $File::Find::dir =~ m!chrome/locale!; # Skip all locale folders
	return if ! m/\.xul$/; # Skip anything that's not a XUL file
	print " - Scanning $_\n";
	
	open my $in, '<:encoding(UTF-8)', $File::Find::name or die "Cannot open $File::Find::name: $!";
	while (<$in>)
	{
		while(m/&([^;]+?);/g)
		{
			my $i = $1;
			if (exists $ids{$i})
			{
				$ids{$i} = $ids{$i} + 1;
			}
			else
			{
				if (exists $unknown{$i})
				{
					$unknown{$i} = $unknown{$i} + 1;
				}
				else
				{
					$unknown{$i} = 1;
				}
			}
		}
	}
	close $in;
}

sub scanMaster
{
	return if $File::Find::dir !~ m!chrome/locale/$masterLocale!;
	return if ! m/\.dtd$/;
	
	print " - Found $_\n";
	open my $in, '<:encoding(UTF-8)', $File::Find::name or die "Cannot open $File::Find::name: $!";
	while (<$in>)
	{
		next if m/^\s*$/; # Skip blank lines
		my ($id) = m/<!ENTITY ([^ \t]+)/;
		$ids{$id} = 0;
	}
	close $in;
}

sub usage
{
print <<USAGE;
Script Usage:
  findOrphanedEntities.pl [Options] [Extension_Root_Dir]
  
This script is used to find entities in Firefox extension locale files that are
not used anywhere in the project. Handy for determining what entities can be
dropped going forward.

LIMITATIONS
At the moment, this script only works on DTD files, not .properties files

[Extension_Root_Directory]
  If provided, specifies the absolute location of the root folder of the
  extension (defaults to the current working directory if not provided)

[Options]
  --master LOCALE-NAME
  Specifies the name of the locale to compare against; defaults to 'en-US'
USAGE
}
