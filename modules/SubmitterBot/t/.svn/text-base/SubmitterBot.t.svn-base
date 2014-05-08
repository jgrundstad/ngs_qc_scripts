# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SubmitterBot.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('SubmitterBot') };
require_ok('SubmitterBot');
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $bot = SubmitterBot->new();
ok( (defined($bot)), "bot is initialized");
my $name = $bot->job_name();
ok( (defined($name)), "job_name method is called: $name");

