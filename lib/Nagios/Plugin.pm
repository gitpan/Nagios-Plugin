# This is only because Class::Struct doesn't allow subclasses
# Trick stolen from Class::DBI
package Nagios::__::Plugin;

use 5.008004;
use Class::Struct;
struct "Nagios::__::Plugin" => {
	perfdata => '@',
	};

package Nagios::Plugin;

use Nagios::Plugin::Base;
use Nagios::Plugin::Performance;
use Nagios::Plugin::Threshold;

use strict;
use warnings;

use Carp;

use Exporter;
our @ISA = qw(Exporter Nagios::__::Plugin);
our @EXPORT_OK = qw(%ERRORS);

our $VERSION = '0.12';

sub add_perfdata {
	my ($self, %args) = @_;
	my $perf = Nagios::Plugin::Performance->new(%args);
	push @{$self->perfdata}, $perf;
}

sub all_perfoutput {
	my $self = shift;
	return join(" ", map {$_->perfoutput} (@{$self->perfdata}));
}

sub set_thresholds { shift; Nagios::Plugin::Threshold->set_thresholds(@_); }

my $shortname;
sub shortname { shift; @_ ? $shortname = shift : $shortname }

sub die {
	my $self = shift;
	my %args = @_;
	Nagios::Plugin::Base->die(\%args, $self);
}

1;
__END__

=head1 NAME

Nagios::Plugin - Object oriented helper routines for your Nagios plugin

=head1 SYNOPSIS

  use Nagios::Plugin qw(%ERRORS);
  $p = Nagios::Plugin->new( shortname => "PAGESIZE" );

  $threshold = $p->set_thresholds( warning => "10:25", critical => "25:" );

  # ... collect current metric into $value
  if ($trouble_getting_metric) {
	$p->die( return_code => $ERRORS{UNKNOWN}, message => "Could not retrieve page");
	# Output: PAGESIZE UNKNOWN Could not retrieve page
	# Return code: 3
  }

  $p->add_perfdata( label => "size",
    value => $value,
    uom => "kB",
    threshold => $threshold,
    );
  $p->add_perfdata( label => "time", ... );

  $p->die( return_code => $threshold->get_status($value), message => "page size at http://... was ${value}kB" );
  # Output: PAGESIZE OK: page size at http://... was 36kB | size=36kB;10:25;25: time=...
  # Return code: 0

=head1 DESCRIPTION

This is the place for common routines when writing Nagios plugins. The idea is to make it as 
easy as possible for developers to conform to the plugin guidelines 
(http://nagiosplug.sourceforge.net/developer-guidelines.html).

=head1 DESIGN

To facilitate object oriented classes, there are multiple perl modules, each reflecting a type of data
(ie, thresholds, ranges, performance). However, a plugin developer does not need to know about the
different types - a "use Nagios::Plugin" should be sufficient.

There is a Nagios::Plugin::Export. This holds all internals variables. You can specify these variables
when use'ing Nagios::Plugin

  use Nagios::Plugin qw(%ERRORS)
  print $ERRORS{WARNING} # prints 1

=head1 VERSIONING

Only methods listed in the documentation for each module is public.

These modules are experimental and so the interfaces may change up until Nagios::Plugin
hits version 1.0, but every attempt will be made to make backwards compatible.

=over 4

=head1 STARTING

=item use Nagios::Plugin qw(%ERRORS)

Imports the %ERRORS hash. This is currently the only symbol that can be imported.

=head1 CLASS METHODS

=item Nagios::Plugin->new( shortname => $$ )

Initializes a new Nagios::Plugin object. Can specify the shortname here.

=head1 OBJECT METHODS

=item set_thresholds( warning => "10:25", critical => "25:" )

Sets the thresholds, based on the range specification at 
http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT. 
Returns a Nagios::Plugin::Threshold object, which can be used to input a value to see which threshold
is crossed.

=item add_perfdata( label => "size", value => $value, uom => "kB", threshold => $threshold )

Adds to an array a Nagios::Plugin::Performance object with the specified values.

This needs to be done separately to allow multiple perfdata output.

=item die( return_code => $ERRORS{CRITICAL}, message => "Output" )

Exits the plugin and prints to STDOUT a Nagios plugin compatible output. Exits with the specified
return code. Also prints performance data if any have been added in.

=back

=head1 SEE ALSO

http://nagiosplug.sourceforge.net

=head1 AUTHOR

Ton Voon, E<lt>ton.voon@altinity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Nagios Plugin Development Team

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
