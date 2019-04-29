package Chef::ServerAPI;
use Mojo::Base -base, -signatures;
use Mojo::URL;
use Mojo::UserAgent;
use Carp();
use Data::Dumper;

our $VERSION = '0.0.1';

has host   => sub{ Mojo::URL->new() || Carp::croak "host is required\n" };
has userId => sub{ Carp::croak "userId is required\n" };
has pem    => sub{ Carp::croak "pem must be provided\n" };
#has version => 12.4.0; # The version of the chef-client executable from which a request is made. This header ensures that responses are in the correct format. For example: 12.0.2 or 11.16.x.

#has 'Server-API-Version' => 1;   # 0 is supported up to Chef v12

# Chef v12.4.0+ support SHA-256 rather than SHA-1 hashing
#has 'authentication_protocol_version' => '1.3'; 

has ua => sub{ Mojo::UserAgent->new };
              
#on(start => sub ($ua, $tx) {
  ## Add authentication headers to requests
#  $tx->req->headers->header('Accept ' => 'application/json');
#  $tx->req->headers->header('Content-Type ' => 'application/json'); # Strictly only needed for PUT or POST
#  $tx->req->headers->header('X-Chef-Version' => ''); # The version of the chef-client executable from which a request is made. This header ensures that responses are in the correct format. For example: 12.0.2 or 11.16.x.
  
#Canonical header format:
#
# Method:HTTP_METHOD
# Hashed Path:HASHED_PATH
# X-Ops-Content-Hash:HASHED_BODY
# X-Ops-Timestamp:TIME
# X-Ops-UserId:USERID
#  $tx->req->headers->header('X-Ops-Authorization-N' => ''); # 	One (or more) 60 character segments that comprise the canonical header. A canonical header is signed with the private key used by the client machine from which the request is sent, and is also encoded using Base64. If more than one segment is required, each should be named sequentially, e.g. X-Ops-Authorization-1, X-Ops-Authorization-2, X-Ops-Authorization-N, where N represents the integer used by the last header that is part of the request.


#  $tx->req->headers->header('X-Ops-Content-Hash' => ''); # The body of the request. The body should be hashed using SHA-1 and encoded using Base64. All hashing is done using SHA-1 and encoded in Base64. Base64 encoding should have line breaks every 60 characters.
#  $tx->req->headers->header('X-Ops-Server-API-Version' => '1'); # 0 is for 12
#  $tx->req->headers->header('X-Ops-Sign' => 'version=1.0');
#  $tx->req->headers->header('X-Ops-Timestamp' => 'TODO'); # 	The timestamp, in ISO-8601 format and with UTC indicated by a trailing Z and separated by the character T. For example: 2013-03-10T14:14:44Z.
#  $tx->req->headers->header('X-Ops-UserId' => 'TODO'); # The name of the API client whose private key will be used to create the authorization header.
#  }) or Carp::Croak("Unable to set up Mojo::UserAgent: $!\n");
#};

# GET /_status
#    (on front-end servers)
#    check the status of communications between the front and back end servers.
sub get_status($self) {
    return $self->ua->get( $self->host ."/_status" )->result;    
}

# GET /license
#   get license information for the Chef server
sub license ($self) {
    Carp::cluck("self contains: ".Data::Dumper::Dumper($self));
    return $self->ua->get( $self->host ."/license" )->result;
}

# GET /organizations
#   get a list of organizations on the Chef server.
# GET /organizations/NAME
#   get the details for the named organization.
sub organizations ($self, $NAME) {
    if ($NAME) {
        return $self->ua->get( $self->host ."/organizations/$NAME" )->result;
    } else {
        return $self->ua->get( $self->host ."/organizations" )->result;
    }
}

# POST /organizations
#   create an organization on the Chef server.
# Note: You could PUT /organizations/NAME to achieve the same end. 
#       Not implementing here, because WTF?
sub create_organization ($self, $name, $full_name) {
    # Going to be slack here and let the server do the validation
    return $self->ua->post($self->host ."/organizations" => json =>
                           { name => $name, full_name => $full_name }
        )->result;
}

# DELETE /organizations/NAME
#    delete an organization.
sub delete_organization ($self, $NAME) {
  return $self->ua->delete( $self->host ."/organizations/$NAME" )->result;
}



# GET /users
#   get a list of users on the Chef server.
#   Filtering on /users can be done with the external_authentication_uid.
#   This is to support SAML authentication. (New in Chef server 12.7.)
sub users ($self, $filter) {
    return $self->ua->get( $self->host ."/users".(
            ($filter) ? '?external_authentication_uid='.$filter : '' 
            ) )->result;
}

# POST /users
#   create a user on the Chef server.
sub create_user_with_details ($self, $user_hash) {
    return $self->ua->
        post($self->host ."/users" => json => $user_hash)->result;
}

# POST /users/USER_NAME
sub create_user_by_name ($self, $name) {
    return $self->ua->
        post($self->host ."/users/$name" => json =>{ name => $name}
        )->result;    
}

# DELETE /users/USER_NAME
#   delete a user
sub delete_user ($self, $NAME) {
  return $self->ua->delete( $self->host ."/users/$NAME" )->result;
}

# GET /users/USER_NAME
#   return the details for a user.
sub get_user ($self, $NAME) {
  return $self->ua->get( $self->host ."/users/$NAME" )->result;
}

# PUT /users/NAME
#   update a specific user.
sub update_user($self, $NAME, $user_hash) {
    return $self->ua->
        put($self->host ."/users/$NAME" => json => $user_hash)->result;
}

# GET /users/USER/keys/
#   retrieve all of the named user’s key identifiers, associated URIs, and expiry states.
sub get_user_keys($self, $NAME) {
  return $self->ua->get( $self->host ."/users/$NAME/keys" )->result;    
}

# POST /users/USER/keys/
#   add a key for the specified user.
sub add_user_key($self, $NAME, $key_hash) {
    return $self->ua->
        post($self->host ."/users/$NAME/keys" => json => $key_hash
        )->result;        
}

# DELETE /users/USER/keys/KEY
#   delete the specified key for the specified user.
sub delete_user_key ($self, $NAME, $key) {
  return $self->ua->delete( $self->host ."/users/$NAME/keys/$key" )->result;
}

# GET /users/USER/keys/KEY
#   return details for a specific key for a specific user.
sub get_user_key($self, $NAME, $key) {
    return $self->ua->get( $self->host ."/users/$NAME/keys/$key" )->result;    
}

# PUT /users/USER/keys/KEY
#   update one or more properties for a specific key for a specific user.
sub update_user_key($self, $NAME, $key_hash) {
    return $self->ua->
        put($self->host ."/users/$NAME/keys/". $key_hash->{name} =>
            json => $key_hash)->result;
}

# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!


# GET /data
#   return a list of all data bags on the Chef server.
sub get_data_bags($self) {
  Carp::cluck("self contains: ".Data::Dumper::Dumper($self));
    return $self->ua->get( $self->host ."/data" )->result;
}

# POST /data
#   create a new data bag on the Chef server.
sub create_data_bag($self, $data_hash) {
    return $self->ua->post($self->host ."/data" => json => $data_hash)->result;
}

# DELETE /data/NAME
#    delete a data bag.
sub delete_data_bag($self, $name) {
    return $self->ua->delete( $self->host ."/data/$name" )->result;
}

# GET /data/NAME
#   return a hash of all entries in the specified data bag.
sub get_data_bag_entries($self, $name) {
    return $self->ua->get( $self->host ."/data/$name" )->result;    
}

# POST /data/NAME
#   create a new data bag item.
sub create_data_bag_item($self, $name, $item_hash) {
    return $self->ua->
        post($self->host ."/data/$name" => json => $item_hash
        )->result;     
}

# DELETE /data/NAME/ITEM
#    delete a key-value pair in a data bag item.
sub delete_data_bag_item($self, $name, $item) {
    return $self->ua->delete( $self->host ."/data/$name/$item" )->result;
}

# GET /data/NAME/ITEM
#   view all of the key-value pairs in a data bag item.
sub get_data_bag_item($self, $name, $item) {
    return $self->ua->get( $self->host ."/data/$name/$item" )->result;    
}

# PUT /data/NAME/ITEM
#   replace the contents of a data bag item with the contents of this request.
sub update_data_bag_item($self, $name, $item, $item_hash) {
    return $self->ua->
        put($self->host ."/data/$name/$item" =>json => $item_hash
            )->result;
}

# Combined method, not in the API!

sub bagsnatcher($self) {
    my $takings = {};
    my $bags = $self->get_data_bags();
    
    unless (200 == $bags->code) {
        $takings->{error} = $bags->code;
        return $takings;
    }
    
    Carp::cluck("Results of bag scan are: ". Data::Dumper::Dumper($bags) );

    my @bag_names = keys %$bags;

    foreach my $bag (@bag_names) {
        my $bag_entries = get_data_bag_entries($bag);
        
        if (200 == $bag_entries->code) {

        Carp::cluck("Results of bag search are: ". Data::Dumper::Dumper($bag_entries) );
            
            my @entry_names = keys %$bag_entries;
            foreach my $item(@entry_names) {
                my $keyvaluepairs = get_data_bag_item($bag, $item);
                
                if (200 == $keyvaluepairs->code) {
                    
                    Carp::cluck("Results of purse search are: ". Data::Dumper::Dumper($keyvaluepairs) );
                    
                    $takings->{$bag}{$item} = $keyvaluepairs;
                } else {
                    Carp::cluck("bagsnatcher: problem getting entries for item '$item' in bag '$bag'\n");
                    $takings->{$bag}{$item}{error} = $keyvaluepairs->code;
                }
            }
        } else {
            Carp::cluck("bagsnatcher: problem getting entries for bag '$bag'\n");
            $takings->{$bag}{error} = $bag_entries->code;
        }
    }
}

# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!
# TODO LOTS OF ORGANIZATION ENDPOINTS!

1;