package WebService::Hatena::Fotolife;
use 5.008_001;
use strict;
use warnings;
use FileHandle;
use Image::Info qw(image_info);
use WebService::Hatena::Fotolife::Entry;

use base qw(XML::Atom::Client);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new
        or return $class->error($class->SUPER::errstr);

    $self->{ua}->agent("WebService::Hatena::Fotolife/$VERSION");
    return $self;
}

sub createEntry {
    my ($self, %param) = @_;

    return $self->error('title and image source are both required')
        unless $param{title} || grep {!$_} @param{qw(filename scalarref)};

    my $PostURI = 'http://f.hatena.ne.jp/atom/post';
    my $image = $self->_get_image($param{filename} || $param{scalarref})
        or return $self->error($self->errstr);

    my $entry = WebService::Hatena::Fotolife::Entry->new;
    $entry->title($self->_encode($param{title}));
    $entry->content(${$image->{content}});
    $entry->content->type($image->{content_type});
    $entry->generator($param{generator} || __PACKAGE__);

    if ($param{folder}) {
        my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
        $entry->set($dc, 'subject', $param{folder});
    }

    $self->SUPER::createEntry($PostURI, $entry);
}

sub updateEntry {
    my ($self, $EditURI, %param) = @_;

    return $self->error('EditURI and title are both required')
        unless $EditURI || $param{title};

    my $entry = WebService::Hatena::Fotolife::Entry->new;
    $entry->title($self->_encode($param{title}));
    $entry->generator($param{generator} || __PACKAGE__);

    if ($param{folder}) {
        my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
        $entry->set($dc, 'subject', $param{folder});
    }

    $self->SUPER::updateEntry($EditURI, $entry);
}

sub getFeed {
    my $self = shift;
    my $FeedURI = 'http://f.hatena.ne.jp/atom/feed';

    $self->SUPER::getFeed($FeedURI);
}

sub _get_image {
    my ($self, $image_source) = @_;
    my $image;

    if (ref $image_source eq 'SCALAR') {
        $image = $image_source;
    } else {
        $image = do {
            local $/ = undef;
            my $fh = FileHandle->new($image_source)
                or return $self->error("can't open $image_source: $!");
            my $content = <$fh>;
            \$content;
        };
    }

    my $info  = Image::Info::image_info($image);
    return $self->error($info->{error}) if $info->{error};

    return {content => $image, content_type => $info->{file_media_type}};
}

sub _encode {
    my $string = $_[1];

    if ($] >= 5.008) {
        require Encode;
        $string = Encode::encode('utf8', $string)
            unless Encode::is_utf8($string);
    }

    $string;
}

1;

__END__

=head1 NAME

WebService::Hatena::Fotolife - A Perl interface to the
Hatena::Fotolife Atom API

=head1 SYNOPSIS

  use WebService::Hatena::Fotolife;

  my $fotolife = WebService::Hatena::Fotolife->new;
     $fotolife->username($username);
     $fotolife->password($password);

  # create a new entry with image filename
  my $EditURI = $fotolife->createEntry(
      title    => $title,
      filename => $filename,
      folder   => $folder,
  );

  # or specify the image source as a scalarref
  my $EditURI = $fotolife->createEntry(
      title     => $title,
      scalarref => \$image_content,
      folder    => $folder,
  );

  # update the entry
  $fotolife->updateEntry($EditURI, title => $title);

  # delete the entry
  $fotolife->updateEntry($EditURI);

  # retrieve the feed
  my $feed = $fotolife->getFeed;
  my @entries = $feed->entries;
  ...

=head1 DESCRIPTION

WebService::Hatena::Fotolife provides an interface to the
Hatena::Fotolife Atom API.

This module is a subclass of L<XML::Atom::Client>, so see also the
documentation of the base class for more usage.

=head1 METHODS

=head2 new

=over 4

  my $fotolife = WebService::Hatena::Fotolife->new;

Creates and returns a WebService::Hatena::Fotolife object.

=back

=head2 createEntry ( I<%param> )

=over 4

  # passing an image by filename
  my $EditURI = $fotolife->createEntry(
      title    => $title,
      filename => $filename,
  );

  # or...

  # a scalar ref to the image content
  my $EditURI = $fotolife->createEntry(
      title     => $title,
      scalarref => $scalarref,
  );

Uploads given image to Hatena::Fotolife. Pass in the image source as a
filename or a scalarref to the image content. There're some more
options described below:

=over 4

=item * title

Title of the image.

=item * filename

Local filename of the image.

=item * scalarref

Scalar reference to the image content itself.

=item * folder

Place, called "folder" in Hatena::Fotolife, you want to upload your
image.

=item * generator

Specifies generator string. Hatena::Fotolife can handle your request
along with it. If not passed, the package name of this modules is
used.

=back

=back

=head2 updateEntry ( I<$EditURI>, I<%param> )

=over 4

  my $EditURI = $fotolife->updateEntry(
      $EditURI,
      title => $title,
  );

Updates the title of the entry at I<$EditURI> with given
options. Hatena::Fotolife Atom API currently doesn't support to update
the image content directly via Atom API.

=back

=head2 getFeed

=over 4

  my $feed = $fotolife->getFeed;

Retrieves the feed. The count of the entries the I<$feed> includes
depends on your configuration of Hatena::Fotolife.

=back

=head2 use_soap ( I<[ 0 | 1 ]> )

=head2 username ( [ I<$username ]> )

=head2 password ( [ I<$password ]> )

=head2 getEntry ( I<$EditURI> )

=head2 deleteEntry ( I<$EditURI> )

=over 4

See the documentation of the base class, L<XML::Atom::Client>.

=back

=head1 SEE ALSO

=over 4

=item * Hatena::Fotolife

http://f.hatena.ne.jp/

=item * Hatena::Fotolife API documentation

http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%A5%D5%A5%A9%A5%C8%A5%E9%A5%A4%A5%D5AtomAPI

=item * L<XML::Atom::Client>

=back

=head1 AUTHOR

Kentaro Kuribayashi, E<lt>kentarok@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 - 2009 by Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut