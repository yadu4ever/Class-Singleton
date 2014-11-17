# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Singleton;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# turn warnings on
$^W = 1;


#========================================================================
#
# define 'MySingleton', a class derived from Class::Singleton 
#
#========================================================================

package DerivedSingleton;

use vars qw(@ISA);
@ISA = qw(Class::Singleton);



#========================================================================
#
# define 'MyOtherSingleton', a class derived from MySingleton 
#
#========================================================================

package AnotherSingleton;

use vars qw(@ISA);
@ISA = qw(DerivedSingleton);



#========================================================================
#
# define 'UniqueSingleton', where we adapt instance() to only allow
# one instance of all and any derived classes.  We do this by forcing 
# all derived classes to call the Class::Singleton instance() method
# masqueraded as UniqueSingleton->instance() (no matter what the derived
# class name might be).  The reference returned is then re-blessed into
# the current derived class.
#
#========================================================================

package UniqueSingleton;

use vars qw(@ISA);
@ISA = qw(Class::Singleton);

sub instance {
    my $self  = shift;
    my $class = ref($self) || $self;

    # create a temporary $self instance blessed into the current
    # UniqueSingleton class so that all derived classes look like a 
    # 'UniqueSingleton' when they call Class::Singleton::instance())
    $self = bless {};

    # call Classs::Singleton->instance() while masquerading...
    $self = $self->SUPER::instance();

    # ...and then bless returned instance into the required class
    bless $self, $class;
}


#========================================================================
#
# create two classes derived from UniqueSingleton which should then be
# mutually exclusive
#
#========================================================================

package UniqueSingletonOne;

use vars qw(@ISA);
@ISA = qw(UniqueSingleton);

sub one { my $self = shift; print "$self->one(", join(', ', @_), ")\n"; };

#------------------------------------------------------------------------

package UniqueSingletonTwo;

use vars qw(@ISA);
@ISA = qw(UniqueSingleton);

sub two { my $self = shift; print "$self->two(", join(', ', @_), ")\n"; };


#========================================================================
#
# We should be able to create one and only once instance of each of
# Class::Singleton, MySingleton and MyOtherSingleton.
#
#========================================================================

package main;

# call Class::Singleton->instance() twice and expect to get the same 
# reference returned on both occasions.

my $s1 = Class::Singleton->instance();

print "Class::Singleton instance 1: ",
    defined($s1) ? ok($s1) : not_ok('<undef>');

my $s2 = Class::Singleton->instance();

print "Class::Singleton instance 2: ",
    (defined($s2) ? ok($s2) : not_ok('<undef>'));

print $s1 == $s2 
    ? ok('Class::Singleton instances are identical') 
    : not_ok('Class::Singleton instances are unique');


# call MySingleton->instance() twice and expect to get the same 
# reference returned on both occasions.

my $s3 = DerivedSingleton->instance();

print "DerivedSingleton instance 1: ", 
    defined($s3) ? ok($s3) : not_ok('<undef>');

my $s4 = DerivedSingleton->instance();

print "DerivedSingleton instance 2: ", 
    defined($s4) ? ok($s4) : not_ok('<undef>');

print $s3 == $s4 
    ? ok("DerivedSingleton instances are identical")
    : not_ok("DerivedSingleton instances are unique");


# call MyOtherSingleton->instance() twice and expect to get the same 
# reference returned on both occasions.

my $s5 = AnotherSingleton->instance();

print "AnotherSingleton instance 1: ",
    defined($s5) ? ok($s5) : not_ok('<undef>');

my $s6 = AnotherSingleton->instance();

print "AnotherSingleton instance 2: ",
    defined($s6) ? ok($s6) : not_ok('<undef>');

print $s5 == $s6 
    ? ok("AnotherSingleton instances are identical")
    : not_ok("AnotherSingleton instances are unique");


#========================================================================
#
# having checked that each instance of the same class is the same, we now
# check that the instances of the separate classes are actually different 
# from each other 
#
#========================================================================

print $s1 != $s3 
    ? ok("Class::Singleton and DerviedSingleton are different") 
    : not_ok("Class::Singleton and DerivedSingleton are identical");
print $s1 != $s5 
    ? ok("Class::Singleton and AnotherSingleton are different") 
    : not_ok("Class::Singleton and AnotherSingleton are identical");
print $s3 != $s5 
    ? ok("DerivedSingleton and AnotherSingleton are different") 
    : not_ok("DerivedSingleton and AnotherSingleton are identical");



#========================================================================
#
# the two classes derived from UniqueSingleton should be mutually 
# exclusive.  That is, the instances of different classes should be 
# the same.
#
#========================================================================

my $s7 = UniqueSingletonOne->instance();

print "UniqueSingetonOne instance 1: ",
    defined($s7) ? ok($s7) : not_ok('<undef>');

# test method calls (one() should work, two() shouldn't)
eval {
    $s7->one("This is one");
};
print $@
    ? not_ok($@)
    : ok("UniqueSingletonOne is correctly blessed (1/2)");

eval {
    $s7->two("This is two");
};
print $@
    ? ok("UniqueSingletonOne is correctly blessed (2/2)")
    : not_ok("Called a non-existant method on UniqueSingletonOne");


my $s8 = UniqueSingletonTwo->instance();

print "UniqueSingetonTwo instance 1: ",
    defined($s8) ? ok($s8) : not_ok('<undef>');

# test method calls (one() shouldn't work, two() should)
eval {
    $s8->two("This is two");
};
print $@
    ? not_ok($@)
    : ok("UniqueSingletonTwo is correctly blessed (1/2)");

eval {
    $s7->one("This is two");
};
print $@
    ? ok("UniqueSingletonTwo is correctly blessed (2/2)")
    : not_ok("Called a non-existant method on UniqueSingletonTwo");


print $s7 == $s8 
    ? ok("UniqueSingleton derived instances are identical")
    : not_ok("UniqueSingleton derived instances instances are unique");


#========================================================================
#
# ok/not_ok subs
#
#========================================================================

sub ok     { 
    return join('', @_ ? (@_, "\n") : (), "ok ", ++$loaded, "\n");
}

sub not_ok { 
    return join('', @_ ? (@_, "\n") : (), "not ok ", ++$loaded, "\n");
}

