use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $tmp = tempdir(CLEANUP => 1);
my $home = File::Spec->catdir($tmp, 'home');
my $dir  = File::Spec->catdir($tmp, 'dir');

make_path(File::Spec->catdir($home, 'mime'));
make_path(File::Spec->catdir($dir, 'mime'));

my $home_globs = File::Spec->catfile($home, 'mime', 'globs');
my $dir_globs  = File::Spec->catfile($dir, 'mime', 'globs');

open my $sys_fh, '>', $dir_globs or die "Could not write $dir_globs: $!";
print {$sys_fh} "application/x-system-doc:*.foo\n";
close $sys_fh or die "Could not close $dir_globs: $!";

open my $home_fh, '>', $home_globs or die "Could not write $home_globs: $!";
print {$home_fh} "application/x-user-doc:*.foo\n";
close $home_fh or die "Could not close $home_globs: $!";

$ENV{XDG_DATA_HOME} = $home;
$ENV{XDG_DATA_DIRS} = $dir;

use_ok('File::MimeInfo', qw(extensions mimetype));

File::MimeInfo::rehash();

is(
    mimetype('document.foo'),
    'application/x-user-doc',
    'XDG_DATA_HOME extension overrides XDG_DATA_DIRS extension',
);

is(
    extensions('application/x-user-doc'),
    'foo',
    'reverse lookup returns the overriding extension mapping',
);

ok(
    extensions('application/x-system-doc') eq '',
    'overridden extension is removed from previous mimetype reverse lookup',
);

done_testing;