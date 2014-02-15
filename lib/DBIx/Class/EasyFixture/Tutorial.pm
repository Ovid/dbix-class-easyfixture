package DBIx::Class::EasyFixture::Tutorial;

# this is not a .pod file because various repos replace the primary
# documentation with a .pod file.

1;

__END__

=head1 NAME

DBIx::Class::EasyFixture::Tutorial - what it says on the tin

=head1 RATIONALE

Managing test data is hard enough without having a clean way of maintaining
fixtures. L<DBIx::Class::EasyFixture> makes it easy to define fixtures.
Different scenarios can be loaded on demand to test different facets of your
system. Fixtures can take a while to write, but once defined, there's less
cutting and pasting of code.

=head1 CREATING YOUR FIXTURE CLASS

To use C<DBIx::Class::EasyFixture>, you must first create a subclass of it.
It's required to define two methods: C<get_fixture> and C<all_fixture_names>.
You may implement those any way you wish and you're not locked into a
particular format. Here's one way to do it, using a big hash (there are plenty
of other ways to do this, but this is easy for a tutorial.

    package My::Fixtures;
    use Moose;
    extends 'DBIx::Class::EasyFixture';

    my %definition_for = (
        # keys are fixture names, values are the fixture definitions
    );

    sub get_definition {
        my ( $self, $name ) = @_;
        return $definition_for{$name};
    }

    sub all_fixture_names { return keys %definition_for }

    __PACKAGE__->meta->make_immutable;

    1;

=head2 A stand-alone fixture

Writing fixtures is easy, so let's start with something simple.

Imagine you have the following table:

    CREATE TABLE people (
        person_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name      VARCHAR(255) NOT NULL,
        email     VARCHAR(255)     NULL UNIQUE,
        birthday  DATETIME     NOT NULL
    );

Its C<DBIx::Class> definition might look like this:

    package Sample::Schema::Result::Person;
    use strict;
    use warnings;
    use base 'DBIx::Class::Core';
    __PACKAGE__->load_components("InflateColumn::DateTime");

    __PACKAGE__->table("people");

    __PACKAGE__->add_columns(
        "person_id",
        { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
        "name",
        { data_type => "varchar", is_nullable => 0, size => 255 },
        "email",
        { data_type => "varchar", is_nullable => 1, size => 255 },
        "birthday",
        { data_type => "datetime", is_nullable => 0 },
    );

    __PACKAGE__->set_primary_key("person_id");
    __PACKAGE__->add_unique_constraint( "email_unique", ["email"] );

    1;

(After this, we won't show much of the C<DBIx::Class> code).

To define a fixture with a birthday, the email C<not@home.com> and the name
C<bob>, you would might have this:

    basic_person => {
        new   => 'Person',
        using => {
            name     => 'Bob',
            email    => 'not@home.com',
            birthday => $datetime_object,
        },
    }

The key C<basic_person> is the name you'll reference this fixture by. Inside 

my $birthday = DateTime->new(
    year  => 1983,
    month => 2,
    day   => 12,
);

my %definition_for = (
    all_people => [qw/person_without_customer person_with_customer/],
    person_without_customer => {
        new   => 'Person',
        using => {
            name     => 'Bob',
            email    => 'not@home.com',
            birthday => $birthday,
        },
    },
