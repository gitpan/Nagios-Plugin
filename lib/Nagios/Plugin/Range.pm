package Nagios::Plugin::Range;

use 5.008004;

use strict;
use warnings;

use overload
        '""' => sub { shift->stringify };

use Class::Struct;
struct "Nagios::Plugin::Range" => {
	start => '$',
	end => '$',
	start_infinity => '$',	# TRUE / FALSE
	end_infinity => '$',	# TRUE / FALSE
	alert_on => '$',	# OUTSIDE 0, INSIDE 1, not defined == range not set
	};

my $outside = 0;
my $inside = 1;

sub stringify {
	my $self = shift;
	return "" unless $self->is_set;
	return (($self->alert_on) ? "@" : "") .
		(($self->start_infinity == 1) ? "~:" : (($self->start == 0)?"":$self->start.":")) . 
		(($self->end_infinity == 1) ? "" : $self->end);
}

sub is_set {
	my $self = shift;
	(! defined $self->alert_on) ? 0 : 1;
}

sub set_range_start {
	my ($self, $value) = @_;
	$self->start($value+0);	# Force scalar into number
	$self->start_infinity(0);
}

sub set_range_end {
	my ($self, $value) = @_;
	$self->end($value+0);	# Force scalar into number
	$self->end_infinity(0);
}

# Returns a N::P::Range object if the string is a conforms to a Nagios Plugin range string, otherwise null
sub parse_range_string {
	my ($class, $string) = @_;
	my $valid = 0;
	my $range = $class->new( start => 0, start_infinity => 0, end => 0, end_infinity => 1, alert_on => $outside);

	if ($string =~ s/^\@//) {
		$range->alert_on($inside);
	}
	if ($string =~ s/^~//) {
		$range->start_infinity(1);
	}
	if (($_) = $string =~ /^([-\d\.]+)?:/) {
		$range->set_range_start($_) if defined $_;
		$string =~ s/^([-\d\.]+)?://;
		$valid++
	}
	if ($string =~ /^([-\d\.]+)$/) {
		$range->set_range_end($string);
		$valid++;
	}

	if ($valid && ($range->start_infinity == 1 || $range->end_infinity == 1 || $range->start <= $range->end)) {
		return $range;
	}
	return undef;
}

# Returns 1 if an alert should be raised, otherwise 0
sub check_range {
	my ($self, $value) = @_;
	my $false = 0;
	my $true = 1;
	if ($self->alert_on == $inside) {
		$false = 1;
		$true = 0;
	}
	if ($self->end_infinity == 0 && $self->start_infinity == 0) {
		if ($self->start <= $value && $value <= $self->end) {
			return $false;
		} else {
			return $true;
		}
	} elsif ($self->start_infinity == 0 && $self->end_infinity == 1) {
		if ($self->start <= $value) {
			return $false;
		} else {
			return $true;
		}
	} elsif ($self->start_infinity == 1 && $self->end_infinity == 0) {
		if ($value <= $self->end) {
			return $false;
		} else {
			return $true;
		}
	} else {
		return $false;
	}
}

1;
__END__

=head1 NAME

Nagios::Plugin::Range - Common range functions for Nagios::Plugin

=head1 DESCRIPTION

Handles common Nagios Plugin range data. See Nagios::Plugin for creation interfaces.

=head1 AUTHOR

Ton Voon, E<lt>ton.voon@altinity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Altinity Limited

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
