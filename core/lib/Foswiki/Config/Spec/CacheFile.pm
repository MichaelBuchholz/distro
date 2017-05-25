# See bottom of file for license and copyright information

package Foswiki::Config::Spec::CacheFile;

use Storable qw(freeze thaw);

use Foswiki::Class;
extends qw(Foswiki::File);

has entries => (
    is      => 'rw',
    lazy    => 1,
    trigger => 1,
    clearer => 1,
    builder => 'prepareEntries',
    isa     => Foswiki::Object::isaARRAY( 'entries', noUndef => 1, ),
);

has specData => (
    is      => 'rw',
    lazy    => 1,
    trigger => 1,
    clearer => 1,
    builder => 'prepareSpecData',
    isa     => Foswiki::Object::isaARRAY('specData'),
);

has fileSize => (
    is      => 'rw',
    lazy    => 1,
    trigger => 1,
    clearer => 1,
    builder => 'prepareFileSize',
);

has _cached => (
    is      => 'rw',
    lazy    => 1,
    builder => '_prepareCached',
    isa     => Foswiki::Object::isaHASH( '_cached', noUndef => 1, ),
);

# inSync is true if cache is in sync with file content.
has inSync => (
    is      => 'rw',
    default => 0,
);

# Defines if cache is in consistent state; i.e. it's been filled in with all the
# data.
# This is different from the inSync attribute as the latter signals if the
# _cached attribute contains same data as the file on disk. Whereas isConsistent
# is about object's internal state.
has isConsistent => (
    is      => 'rwp',
    lazy    => 1,
    clearer => 1,
    trigger => 1,
    builder => 'prepareIsConsistent',
);

sub storeNodes {
    my $this = shift;

    my @entries;
    foreach my $node (@_) {
        push @entries, [ $node->fullName => $node->default ];
    }

    $this->entries( \@entries );
}

sub invalidate {
    my $this = shift;

    $this->inSync(0);
}

around flush => sub {
    my $orig = shift;
    my $this = shift;

    return if $this->inSync;

    $this->content( freeze( $this->_cached ) );

    $orig->( $this, @_ );

    $this->inSync(1);
};

# Declare cache is complete – i.e. it's now in consistent state and can be
# flushed on disk. This is the method to be used instead of flush().
sub complete {
    my $this = shift;

    $this->_set_isConsistent(1);
    $this->flush;
}

sub incomplete {
    my $this = shift;

    $this->_set_isConsistent(0);
    $this->invalidate;
}

sub _prepareCached {
    my $this = shift;

    $this->invalidate;
    my $content = $this->content;

    return {} unless $content;

    my $data = thaw($content);

    $this->inSync(1);
    $this->clear_entries;
    $this->clear_specData;

    return $data;
}

sub prepareEntries {
    my $this = shift;

    my $entries = thaw( $this->_cached->{entries} );

    return $entries;
}

sub prepareSpecData {
    my $this = shift;

    my $cachedData = $this->_cached->{specData};
    return undef unless defined $cachedData;

    return thaw($cachedData);
}

sub prepareFileSize {
    return $_[0]->_cached->{fileSize};
}

sub prepareIsConsistent {
    return $_[0]->_cached->{isConsistent} // 0;
}

sub _trigger_entries {
    my $this    = shift;
    my $entries = shift;

    $this->_cached->{entries} = freeze($entries);
    $this->incomplete;
}

sub _trigger_specData {
    my $this     = shift;
    my $specData = shift;

    $this->_cached->{specData} = freeze($specData);
    $this->incomplete;
}

sub _trigger_fileSize {
    my $this = shift;
    my $size = shift;

    $this->_cached->{fileSize} = $size;
    $this->incomplete;
}

sub _trigger_isConsistent {
    my $this = shift;
    my $val  = shift;

    if ($val) {
        $this->_cached->{isConsistent} = $val;
    }
    else {
        delete $this->_cached->{isConsistent};
    }
}

around prepareUnicode => sub {
    return 0;
};

around prepareBinary => sub {
    return 1;
};

around prepareAutoWrite => sub {
    return 0;
};

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2016 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
