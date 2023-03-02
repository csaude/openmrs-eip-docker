#!/usr/bin/expect -f

set cert_path [lindex $argv 0];
set JAVA_HOME $::env(JAVA_HOME) 

set timeout -1


puts "REGISTERING $cert_path CERTIFICATE TO TRUSTED CERTIFICATES"

spawn keytool -import -trustcacerts -file $cert_path -alias artemis -keystore $JAVA_HOME/jre/lib/security/cacerts 

	expect "Enter keystore password: "
	send -- "changeit\n"
	expect "Trust this certificate?*"
	send -- "yes\n"

puts "CERTIFICATE ADDED TO TRUSTED CETIFICATE"

expect eof
