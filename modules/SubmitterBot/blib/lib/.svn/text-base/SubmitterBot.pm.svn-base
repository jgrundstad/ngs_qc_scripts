package SubmitterBot;

use 5.010001;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SubmitterBot ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(new new_job_wait_time submit_wait_time ppn max_jobs job_name jobs batch start_bot);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
    my $self = {
		new_job_wait_time => 20,
		submit_wait_time => 2,
		ppn => 1,
		max_jobs => 1,
		job_name => "job_name",
		jobs => []
	};
	bless($self);
    return $self;
}

sub new_job_wait_time {
	my $self = shift;
	if(@_) { $self->{new_job_wait_time} = shift; }
	return $self->{new_job_wait_time};
}

sub submit_wait_time {
	my $self = shift;
	if(@_) { $self->{submit_wait_time} = shift; }
	return $self->{submit_wait_time};
}

sub ppn {
	my $self = shift;
	if(@_) { $self->{ppn} = shift; }
	return $self->{ppn};
}

sub max_jobs {
	my $self = shift;
	if(@_) { $self->{max_jobs} = shift; }
	return $self->{max_jobs};
}

sub job_name {
	my $self = shift;
	if(@_) { $self->{job_name} = shift; }
	return $self->{job_name};
}

sub jobs {
	my $self = shift;
	if(@_) { $self->{jobs} = shift; }
	return $self->{jobs};
}

sub batch {
	my $self = shift;
	if(@_) { $self->{batch} = shift; }
	return $self->{batch};
}

sub submit_jobs {

    my $self = shift;
    carp "called without a reference" if (!ref($self));

    my $new_job_wait_time = $self->{new_job_wait_time}; # seconds between checks when max nodes is reached
    my $submit_wait_time = $self->{submit_wait_time};   # seconds after submitting to let scheduler react
    my $ppn = $self->{ppn};          # processors per node for alignments
    my $job_name = $self->{job_name};
	my $max_jobs = $self->{max_jobs};
	my @revcmds = @{$self->{jobs}};
	my @cmds = reverse @revcmds;
    my $total_cmds = $#cmds + 1;
    my $batch = $self->{batch}; # name the batch of commands for monitoring's sake.

	# monitor queue, submit as needed until the jobs are done
    while($#cmds > -1) {
        my $q = query_qstat($job_name);
        my $cmds_left = $#cmds + 1;
        print STDERR "commands left in batch[$batch]: $cmds_left/$total_cmds    in queue: $q/$max_jobs(max)\n";
        if(query_qstat($job_name) >= $max_jobs) {
            #print STDERR "!! more jobs than max, waiting 3sec\n";
            sleep($self->{new_job_wait_time});
        }else{
            for(1 .. $max_jobs - query_qstat($job_name)) {
                if($#cmds > -1) {
                    my $cmd = pop @cmds;
                    `echo \"$cmd\" >> submitter_bot.log`;
                    my $cmd_ret = `$cmd`;
                    chomp $cmd_ret;
                    `echo "$cmd_ret" >> submitter_bot.log`;
                    #print STDERR "cmd_ret: $cmd_ret\n";
                    #print STDERR "LOOPING: waiting 3sec\n";
                    sleep($self->{submit_wait_time});
                }
            }
        }
    }
}

sub query_qstat {
    my $qstring = shift;
    my $out = `qstat -r | grep -c $qstring`;
    chomp $out;
    return $out;
}

1;
__END__

=head1 NAME

SubmitterBot - Perl extension for high-throughput sequence alignment and QC on a Torque/pbs_sched based queue

=head1 SYNOPSIS

  use SubmitterBot;
  my $bot = new SubmitterBot;

  $bot->new_job_wait_time(20);		# time between checks that we're running the max number of jobs
  $bot->submit_wait_time(2);		# time between job submissions, avoid choking scheduler with rapid submissions.
  $bot->ppn(8);						# how many processors per node to use
  $bot->max_jobs(3);				# maximum number of jobs to have in the queue at one time
  $bot->job_name("uniq_string");	# unique identifier used to monitor jobs in queue
  $bot->jobs(\@cmd_array);			# array of qsub commands to submit to bot
  $bot->batch("string");			# string to allow for log identification of this batch from the next

  $bot->start_bot();				# FIRE!

=head1 DESCRIPTION

This module helps maximise Torque scheduler usage by maximising resource usage required by IGSB sequence alignment and QC algorithms.

=head2 Methods

=over 4

=item * $object->new_job_wait_time(int or blank)

=item * $object->submit_wait_time(int or blank)

=item * $object->ppn(int or blank)

=item * $object->max_jobs(int or blank)

=item * $object->job_name(string or blank)

=item * $object->jobs(array or blank)

=item * $object->batch(string or blank)

=item * $object->start_bot()

=back

=head2 EXPORT

=over 4

=item * $object->start_bot()

=back

=head1 AUTHOR

Jason Grundstad, E<lt>jgrundstad@uchicago.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jason Grundstad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
