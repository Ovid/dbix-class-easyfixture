package DBIx::Class::SimpleFixture::Definition;
use Moose;
use Carp;
use Storable 'dclone';
use namespace::autoclean;

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'definition' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

around 'BUILDARGS' => sub {
    my $orig = shift;
    my $self = shift;
    my $args = dclone(shift);
    $self->$orig($args);
};

sub BUILD {
    my $self  = shift;
    $self->_validate_class_and_data;
    $self->_validate_children;
    $self->_validate_parents;
}

sub resultset_class  { shift->definition->{class} }
sub constructor_data { shift->definition->{data} }
sub children         { shift->definition->{children} }
sub parents          { shift->definition->{parents} }

sub _validate_class_and_data {
    my $self = shift;

    my $class = $self->resultset_class;
    my $data  = $self->constructor_data;

    if ( $class xor $data ) {
        my $found   = $class ? 'class' : 'data';
        my $missing = $class ? 'data'  : 'class';
        my $name    = $self->name;
        croak("Fixture '$name' had a '$found' without a '$missing'");
    }
}

sub _validate_children {
    my $self = shift;
    my $children = $self->children or return;

    $children = [$children] unless 'ARRAY' eq ref $children;
    foreach my $child (@$children) {
        if ( !defined $child ) {
            my $name = $self->name;
            croak("Undefined child found for $name");
        }
        if ( my $ref = ref $child ) {
            croak("All children must be strings, not '$ref'");
        }
    }
}

sub _validate_parents {
    my $self = shift;
    my $parents = $self->parents or return;

    unless ( 'HASH' eq ref $parents ) {
        my $name = $self->resultset_class;
        croak("parents for '$name' does not appear to be a hashref");
    }

    while ( my ( $parent, $methods ) = each %$parents ) {
        my $name = $self->resultset_class . ".parents.$parent";
        if ( my @bad_keys = grep { !/^(?:me|parent)$/ } keys %$methods ) {
            croak("Bad keys found for $name: @bad_keys");
        }
        unless ( my $my_method = $methods->{me} ) {
            croak("$name requires 'me'");
        }
        unless ( my $parent_method = $methods->{parent} ) {
            croak("$name required 'parent'");
        }
    }
}


__PACKAGE__->meta->make_immutable;

1;
