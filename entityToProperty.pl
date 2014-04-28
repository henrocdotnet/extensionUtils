#!/usr/bin/perl
use strict;
use warnings;

our $VERSION = "1.00";

use Cwd;
use File::Find;
use Getopt::Long;

my $inputFile = '';
my $targetFile = '';

GetOptions("input=s" => \$inputFile,
		   "target=s" => \$targetFile,
		   "help" => sub { usage(); exit 0; });

my $cwd = getcwd();
my $tempFile = 'tempConverter.properties';
my %table = ();

print "Entity to Property Converter v$VERSION\n\n";
print "Parameters\n";
print " - Input file:    $inputFile\n";
print " - Target file:   $targetFile\n\n";

if (! $inputFile)
{
	print "ERROR: Input file is required!\n\n";
	usage();
	exit 1;
}

if (! $targetFile)
{
	print "ERROR: Target file is requried!\n\n";
	usage();
	exit 1;
}

my %map = (); # Holds the mapping between entity ID and variable name
open my $in, '<', $inputFile or die "Cannot open $inputFile: $!";
while (<$in>)
{
	chomp;
	s/^\s*//;
	s/\s*$//;
	my ($id, $variable) = (m/([a-zA-Z0-9_.-]+)\s+=>\s+(.*)/);
	$map{$id} = $variable;
}
close $in;

print "Transformations to be made:\n";
foreach (sort keys %map)
{
	print " - $_ => $map{$_}\n";
}

print "\nLoading entities to convert...\n\n";
find(\&scanLocales, $cwd);

print "\nUpdating properties files with new entries...\n\n";
find(\&updateEntries, $cwd);

exit 0;

sub scanLocales
{
	return if $File::Find::name !~ m!chrome/locale!;
	return if ! m/\.dtd$/;
	
	my $id = $File::Find::dir;
	$id =~ s!^.+/(.+)$!$1!;
	
	printf("%7s\n", $id);
	
	open my $in, '<:encoding(UTF-8)', $File::Find::name or die "Cannot open $File::Find::name: $!";
	while (<$in>)
	{
		foreach my $k (keys %map)
		{
			if (m/\Q$k\E/)
			{
				my ($value) = (m/"([^"]+)"/);
				$table{$id}{$k} = $value;
				last;
			}
		}
	}
	close $in;
}

sub updateEntries
{
	return if $File::Find::name !~ m!chrome/locale!;
	return if ! m/$targetFile/;
	
	my $id = $File::Find::dir;
	$id =~ s!^.+/(.+)$!$1!;
	
	printf("%7s => %s ... ", $id, $targetFile);
	
	my %vars = ();
	open my $in, '<:encoding(UTF-8)', $File::Find::name or die "Cannot open $File::Find::name: $!";
	while (<$in>)
	{
		next if m/^#/; # Skip comments
		if (m/(\w+)\s*=/)
		{
			$vars{$1} = 1;
		}
	}
	close $in;
	
	my $updated = 0;
	my $skipped = 0;
	
	open my $out, '>>:encoding(UTF-8)', $File::Find::name or die "Cannot open $File::Find::name: $!";
	foreach my $k (keys %map)
	{
		if (! exists $vars{$map{$k}})
		{
			print $out $map{$k} . "=" . $table{$id}{$k} . "\n";
			$updated++;
		}
		else
		{
			$skipped++;
		}
	}
	close $out;
	
	printf("%d updated, %d skipped\n", $updated, $skipped);
}

sub usage
{
print <<USAGE;
Script Usage:
  entityToProperty.pl --input FILENAME --target FILENAME
  
Description:
  This script converts specific, localized DTD entities into corresponding
  values in a .properties file. Useful for easily moving DTD strings into a
  .properties file for use in JavaScript. Note that the .properties file must
  already exist (this script will not create a new file).
  
--input FILENAME
  Specifies the filename that contains the mapping. See the section on mapping
  entities below for more information.
  
--target FILENAME
  Specifies the name of the .properties file into which the new property
  entries should be placed.
  
Mapping Entities:
  The input file should include a mapping of entities to properties, and should
  be formatted as shown below:
  
    some.entity.id => SomeJavascriptVariable
  
  For example:
  
    gblite.confirm.title => GBL_HistoryConfirmTitle
  
  This example would make the following transformation:
  
  <!ENTITY gblite.confirm.title "Some string here">    <-- From some_file.dtd
  GBL_HistoryConfirmTitle=Some string here             <-- To target.properties
  
Example Usage:
  entityToProperty.pl --input map.txt --target myExtension.properties
USAGE
}
