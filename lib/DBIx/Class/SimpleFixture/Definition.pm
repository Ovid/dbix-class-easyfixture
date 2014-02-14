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
    my $self = shift;
    $self->_validate_class_and_data;
    $self->_validate_next;
    $self->_validate_required_objects;
}

sub resultset_class  { shift->definition->{class} }
sub constructor_data { shift->definition->{data} }
sub next             { shift->definition->{next} }
sub requires         { shift->definition->{requires} }

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

sub _validate_next {
    my $self = shift;
    my $next = $self->next or return;

    $next = [$next] unless 'ARRAY' eq ref $next;
    foreach my $child (@$next) {
        if ( !defined $child ) {
            my $name = $self->name;
            croak("Undefined child found for $name");
        }
        if ( my $ref = ref $child ) {
            croak("All items for 'next' must be strings, not '$ref'");
        }
    }
}

sub _validate_required_objects {
    my $self = shift;
    my $requires = $self->requires or return;

    unless ( 'HASH' eq ref $requires ) {
        my $name = $self->resultset_class;
        croak("$name.requires does not appear to be a hashref");
    }

    while ( my ( $parent, $methods ) = each %$requires ) {
        my $name = $self->resultset_class . ".requires.$parent";
        if ( my @bad_keys = grep { !/^(?:our|their)$/ } keys %$methods ) {
            croak("Bad keys found for $name: @bad_keys");
        }
        unless ( exists $methods->{our} ) {
            croak("$name requires 'our'");
        }
        unless ( exists $methods->{their} ) {
            croak("$name required 'their'");
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
