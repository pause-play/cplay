package App::next::Index::Modules;

use App::next::std;    # import strict, warnings & features
use App::next::Indexes;

use App::next::Logger;    # import all

use base 'App::next::Index';

use App::next::Search::Result ();

use Simple::Accessor qw{file cli};

with 'App::next::Roles::JSON';
with 'App::next::Index::Role::Columns';    # provides columns and sorted_columns

=pod

=head1 Available columns

    my $module_ix             = $self->columns->{module};
    my $version_ix            = $self->columns->{version};
    my $repository_ix         = $self->columns->{repository};
    my $repository_version_ix = $self->columns->{repository_version};

=cut

sub build ( $self, %opts ) {

    $self->{file} = App::next::Indexes::get_modules_ix_file( $self->cli );

    return $self;
}

sub search ( $self, $module, $version = undef ) {
    FATAL("Missing module") unless defined $module;
    INFO("search module $module");

    my $ix = $self->columns->{module};    # should always be 0

    my $result;
    my $iterator = sub($raw) {
        return unless $raw->[$ix] eq $module;

        if ( defined $version ) {
            my $v_ix = $self->columns->{version};
            if ( $raw->[$v_ix] ne $version ) {
                DEBUG( "requested $module version $version ; latest is " . $raw->[$v_ix] );
                return;
            }
        }
        $result = $self->raw_to_hash($raw);
        return 1;    # stop the iterator
    };

    $self->iterate($iterator);

    return $result;
}

sub regexp_search ( $self, $pattern ) {

    return unless defined $pattern && length $pattern;

    my $result = App::next::Search::Result->new;

    my $module_ix     = $self->columns->{module};
    my $repository_ix = $self->columns->{repository};

    my $iterator = sub($raw) {
        if ( $raw->[$module_ix] =~ m{$pattern}i ) {
            $result->add_module( $raw->[$module_ix] );

            # maybe also add the repository
            # $result->add_repository( $raw->[$repository_ix] );
        }

        if ( $raw->[$repository_ix] =~ m{$pattern}i ) {
            $result->add_repository( $raw->[$repository_ix] );
        }

        return;    # continue the search [maybe add a limit??]
    };

    $self->iterate($iterator);

    return $result;
}

1;
