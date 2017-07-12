#!/usr/bin/perl

#   Copyright 2017 Paul Hill paul@hillsys.org
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my @nameServerData = GetNameServers();
my ($defaultGateway, @routeData) = GetRoutesAndGateway();
my @interfaceData = GetInterfaces();
my @driveData = GetDriveSpace();

GetOptions( 
	'show' => \&ShowOutput, 
	'xml' => \&XMLOutput,
	'json' => \&JSONOutput,
	'yaml' => \&YAMLOutput,
	'help' => \&Help,
) or die Help();

sub GetDriveSpace {
	my @lines = split('\n',`df -h | grep /sd`);
	my @output;
	
	$output[0] = ["FileSystem", "Size", "Used", "Available", "PercentageUsed", "Mount"];
	
	for (my $loopCounter = 0; $loopCounter < scalar(@lines); $loopCounter++) {
		my @lineSplit = split(" ", $lines[$loopCounter]);
		$output[$loopCounter + 1] = [$lineSplit[0], $lineSplit[1], $lineSplit[2], $lineSplit[3], $lineSplit[4], $lineSplit[5]]
	}
	
	return @output;
}

sub GetInterfaces {
	my $hasGateway = 0;
	my @lines = split('\n',`ip addr`);
	my $lineCount = 0;
	my $loopCount = 1;
	my @outputData;  #Two dimensional array, first row is heading for CSV file out.

	$outputData[0] = ["Interface", "MTU", "MAC", "IPv4", "Gateway" ];

	do {
		if($lines[($lineCount)] =~ /^\d*:\s([\d\w]*):.*mtu\s(\d*).*/) {
			if($lineCount > 0){ $loopCount++; } # advance to next array sequence after first run
			$outputData[$loopCount][0] = $1; #Interface
			$outputData[$loopCount][1] = $2; #MTU
		}
		elsif($lines[$lineCount] =~ /^.*\/.*\s(..:..:..:..:..:..)\s.*/){
			$outputData[$loopCount][2] = $1; #MAC
		}
		elsif($lines[$lineCount] =~ /^\s*inet\s(\d*\.\d*\.\d*\.\d*\/\d*).*/) {
			$outputData[$loopCount][3] = $1; #IPv4
		}
			
		if(!$hasGateway && $outputData[$loopCount][3]) {
			if(SubnetMatch($defaultGateway, $outputData[$loopCount][3])) {
				$outputData[$loopCount][4] = $defaultGateway;
				$hasGateway++;
			}
		}
		
		$lineCount++;
	} while ($lineCount < scalar(@lines));
	
	return @outputData;
}

sub GetRoutesAndGateway {
	my @routes = split('\n',`route --numeric`);
	my @outputData;
	my $outputGateway;
	
	$outputData[0] = ["Destination", "Gateway", "Subnet Mask", "Interface"];

	for (my $loopCounter = 2; $loopCounter < scalar(@routes); $loopCounter++) {
		$routes[$loopCounter] =~ /((\d*\.){3}\d*)\s*((\d*\.){3}\d*)\s*((\d*\.){3}\d*)\s*\w*\s*\d*\s*\d*\s*\d*\s*(.*)/;
		$outputData[$loopCounter] = [$1, $3, $5, $7];
		
		if($outputData[$loopCounter][0] eq '0.0.0.0' && !$outputGateway) {
			$outputGateway = $outputData[$loopCounter][1];
		}
	}
	
	return ($outputGateway, @outputData);
}

sub GetNameServers {
	#Because not all name servers are listed in /etc/network/interfaces for dhcp clients, use /etc/resolv.conf
	my @output = split('\n', `cat /etc/resolv.conf | grep nameserver`); 
	
	for (my $loopCounter = 0; $loopCounter < scalar(@output); $loopCounter++) {
		$output[$loopCounter] =~ s/.*\s(\d*\.\d*\.\d*\.\d*)/$1/;
		$output[$loopCounter] =~ s/\s+$//;
	}
	
	return @output;
}

sub SubnetMatch {
	my $output = 0;
	my $address1 = $_[0];
	(my $address2 = $_[1]) =~ /(.*)\/(.*)/;

	if(substr(ConvertIPToBinary($address1), 0, $2) eq substr(ConvertIPToBinary($1), 0, $2)) {
		$output = 1;
	}
	
	return $output;
}

sub ConvertIPToBinary {
	(my $address = $_[0]) =~ /(\d*)\.(\d*)\.(\d*)\.(\d*).*/;
	my @binary = (sprintf ("%b", $1), sprintf ("%b", $2), sprintf ("%b", $3), sprintf ("%b", $4));
	
	foreach my $octet (@binary) {
		$octet = "0" x (8-length($octet)) . $octet; #Add any necessary preceeding zeros to binary
	}

	return ($binary[0] . $binary[1] . $binary[2] . $binary[3]);
}

# Output Section

sub ShowOutput { 
	for (my $loopCounter = 0; $loopCounter < scalar(@interfaceData); $loopCounter++) {
		print "$interfaceData[$loopCounter][0]" . " " x (12 - length($interfaceData[$loopCounter][0]));
		
		if ($interfaceData[$loopCounter][1]) {
			print "$interfaceData[$loopCounter][1]" . " " x (8 - length($interfaceData[$loopCounter][1]));
		}
		
		if ($interfaceData[$loopCounter][2]) {
			print "$interfaceData[$loopCounter][2]";
		}
		
		if ($interfaceData[$loopCounter][3]) {
			print " " x (20 - length($interfaceData[$loopCounter][2])) . "$interfaceData[$loopCounter][3]";
			
			if($interfaceData[$loopCounter][4]) {
				print " " x (18 - length($interfaceData[$loopCounter][3])) . "$interfaceData[$loopCounter][4]";
			}
		}
		
		print "\n";
	}
	
	print "\nNameServers:  ";
	
	foreach my $value (@nameServerData) {
		print "$value  ";
	}
	
	print "\n\n";
	
	for (my $loopCounter = 0; $loopCounter < scalar(@driveData); $loopCounter++) {
		
		print "$driveData[$loopCounter][0]" . " " x (13 - length($driveData[$loopCounter][0]));
		print "$driveData[$loopCounter][1]" . " " x (9 - length($driveData[$loopCounter][1]));
		print "$driveData[$loopCounter][2]" . " " x (9 - length($driveData[$loopCounter][2]));
		print "$driveData[$loopCounter][3]" . " " x (11 - length($driveData[$loopCounter][3]));
		print "$driveData[$loopCounter][4]" . " " x (16 - length($driveData[$loopCounter][4]));
		print "$driveData[$loopCounter][5]\n";
	}
}

sub XMLOutput {
	print "<?xml version=\"1.0\"?>\n<System>\n";

	for (my $loopCounter = 1; $loopCounter < scalar(@interfaceData); $loopCounter++) {
		print "\t<Network>\n";
		
		for (my $printCounter = 0; $printCounter < 5; $printCounter++) {
			if($interfaceData[$loopCounter][$printCounter]) {
				print "\t\t<$interfaceData[0][$printCounter]>$interfaceData[$loopCounter][$printCounter]</$interfaceData[0][$printCounter]>\n";
			}
			else {
				print "\t\t<$interfaceData[0][$printCounter]/>\n";
			}
		}
			
		print "\t</Network>\n";
	}
	
	print "\t<DNS>\n";
	
	foreach my $value (@nameServerData) {
		print "\t\t<NameServer>$value</NameServer>\n";
	}
	
	print "\t</DNS>\n";
	
	for (my $loopCounter = 1; $loopCounter < scalar(@driveData); $loopCounter++) {
		print "\t<Drive>\n";
		
		for (my $secondCounter = 0; $secondCounter < 5; $secondCounter++) {
			print "\t\t<$driveData[0][$secondCounter]>$driveData[$loopCounter][$secondCounter]</$driveData[0][$secondCounter]>\n";
		}
		
		print "\t</Drive>\n";
	}
	
	print"</System>\n";
}

sub JSONOutput {
	print "{\n  \"System\": {\n    \"Network\": [\n";
	
	for (my $loopCounter = 1; $loopCounter < scalar(@interfaceData); $loopCounter++) {
		print "      {\n";
		for (my $printCounter = 0; $printCounter < 5; $printCounter++) {
			if($interfaceData[$loopCounter][$printCounter]) {
				print "        \"$interfaceData[0][$printCounter]\": \"$interfaceData[$loopCounter][$printCounter]\"";
				if($interfaceData[$loopCounter][$printCounter + 1]) {
					print ",\n";
				}
				else {
					print "\n      }";
					if($loopCounter + 1 == scalar(@interfaceData)) {
						print "\n";
					}
					else {
						print ",\n";
					}
				}
			}
		}
	}
	
	print "    ]\n    \"DNS\": [\n";
	
	for (my $loopCounter = 0; $loopCounter < scalar(@nameServerData); $loopCounter++) {
		print "      {\n        \"NameServer\": \"$nameServerData[$loopCounter]\"\n      }";
		
		if($loopCounter + 1 == scalar(@nameServerData)) {
			print "\n";
		}
		else {
			print ",\n";
		}
	}
	
	print "    ]\n    \"Drives\": [\n";
	
	for (my $loopCounter = 1; $loopCounter < scalar(@driveData); $loopCounter++) {
		print "      {\n";
		
		for (my $secondCounter = 0; $secondCounter < 5; $secondCounter++) {
			print "        \"$driveData[0][$secondCounter]\": \"$driveData[$loopCounter][$secondCounter]\"\n";
		}
		
		if($loopCounter + 1 == scalar(@driveData)) {
			print "      }\n";
		}
		else {
			print "      },\n";
		}
	}
	
	print "    ]\n  }\n}\n";
}

sub YAMLSpacing {
	my ($recordCount) = @_;
	my $output = 0;
	
	if($recordCount > 1) {
		$output = 1;
	}
	
	return $output;
}

sub YAMLOutput {
	my $interfaceCount = scalar(@interfaceData);
	my $nameServerCount = scalar(@nameServerData);
	my $driveCount = scalar(@driveData);

	print "System:\n Network:\n";
	
	for (my $loopCounter = 1; $loopCounter < $interfaceCount; $loopCounter++) {
		if(YAMLSpacing($interfaceCount)) {
			print "  -\n";
		}
		
		for (my $printCounter = 0; $printCounter < 5; $printCounter++) {
			print " " x YAMLSpacing($interfaceCount) . "   $interfaceData[0][$printCounter]: \"";
			
			if($interfaceData[$loopCounter][$printCounter]){
				print "$interfaceData[$loopCounter][$printCounter]\"\n";
			}
			else {
				print "\"\n";
			}
		}
	}
	
	print " NameServers:\n";
	
	for (my $loopCounter = 0; $loopCounter < $nameServerCount; $loopCounter++) {
		if(YAMLSpacing($nameServerCount)) {
			print "  -\n". " " x YAMLSpacing($nameServerCount) . "   NameServer: \"$nameServerData[$loopCounter]\"\n";
		}
		else {
			print " " x YAMLSpacing($nameServerCount) . "   NameServer: \"$nameServerData[$loopCounter]\"\n";
		}
	}

	print " Drives:\n";
	
	for (my $loopCounter = 1; $loopCounter < $driveCount; $loopCounter++) {
		if(YAMLSpacing($driveCount)) {
			print "  -\n";
		}
		
		for (my $secondCounter = 0; $secondCounter < 5; $secondCounter++) {
			print " " x YAMLSpacing($driveCount) . "   $driveData[0][$secondCounter]: \"$driveData[$loopCounter][$secondCounter]\"\n";
		}
	}
}

# Make a better help file
sub Help {
	my $output = "Usage: $0 ";
	$output = $output . "\n\tGNU\t\tPOSIX\t\tDescription";
	$output = $output . "\n\t--show\t\t-s\t\tDisplay on screen formatting.";
	$output = $output . "\n\t--json\t\t-j\t\tSend output in JSON format.";
	$output = $output . "\n\t--xml\t\t-x\t\tSend output in XML format.";
	$output = $output . "\n\t--yaml\t\t-y\t\tSend output in YAML format.";
	$output = $output . "\n\t--help\t\t-h\t\tDisplays this message.\n";
	print "$output";
}
