package Scanner;
use strict;
use warnings;
use TokenType;
use Token;

sub new {
  my ($class, $args) = @_;
  return bless {
    source  => $args->{source},
    tokens  => [],
    current => 0,
    column  => 0,
    line    => 1,
    blocks  => [],
    errors  => [],
    eof     => undef,
  }, $class;
}

sub print {
  my ($self) = @_;
  for ($self->{tokens}->@*) {
    printf "% 3d % 3d % -15s %s\n", $_->{line}, $_->{column}, TokenType::type($_->{type}), $_->{lexeme};
  }
}

sub scan_tokens {
  my $self = shift;
  while (!$self->{eof}) {
    $self->scan_token;
  }
}

sub scan_token {
  my $self = shift;
  my $c = $self->advance;

  if ($c eq '') {
    $self->chomp_eof($c);
    return;
  }
  elsif ($c eq '(') {
    $self->new_token(lexeme=>$c, type=>LEFT_PAREN);
  }
  elsif ($c eq ')') {
    $self->new_token(lexeme=>$c, type=>RIGHT_PAREN);
  }
  elsif ($c eq '{') {
    $self->new_token(lexeme=>$c, type=>LEFT_BRACE);
  }
  elsif ($c eq '}') {
    $self->new_token(lexeme=>$c, type=>RIGHT_BRACE);
  }
  elsif ($c eq ',') {
    $self->new_token(lexeme=>$c, type=>COMMA);
  }
  elsif ($c eq '.') {
    $self->new_token(lexeme=>$c, type=>DOT);
  }
  elsif ($c eq '-') {
    $self->new_token(lexeme=>$c, type=>MINUS);
  }
  elsif ($c eq '+') {
    $self->new_token(lexeme=>$c, type=>PLUS);
  }
  elsif ($c eq ';') {
    $self->new_token(lexeme=>$c, type=>SEMICOLON);
  }
  elsif ($c eq '*') {
    $self->new_token(lexeme=>$c, type=>STAR);
  }
  elsif ($c eq '!') {
    $self->chomp_bang($c);
  }
  elsif ($c eq '.') {
    $self->chomp_method($c);
  }
  elsif ($c eq '=') {
    $self->chomp_equal($c);
  }
  elsif ($c eq '>') {
    $self->chomp_greater($c);
  }
  elsif ($c eq '<') {
    $self->chomp_less($c);
  }
  elsif ($c eq '/') {
    $self->chomp_slash($c);
  }
  elsif ($c eq ' ' || $c eq "\t") {
    undef;
  }
  elsif ($c eq "\n") {
    $self->{line}++;
    $self->{column} = 0;
  }
  elsif ($c eq '"') {
    $self->chomp_string($c);
  }
  elsif ($c =~ /\d/) {
    $self->chomp_number($c);
  }
  elsif ($c =~ /\w/) {
    $self->chomp_identifier($c);
  }
  else {
    $self->lex_error($c);
  }
}

sub is_at_end {
  my $self = shift;
  return $self->{current} >= length $self->{source};
}

sub match {
  my ($self, $expected_char) = @_;
  if (!$self->is_at_end && $self->peek eq $expected_char) {
    $self->{current}++;
    return 1;
  }
  return undef;
}


sub advance {
  my $self = shift;
  $self->{column}++;
  return substr $self->{source}, $self->{current}++, 1;
}

sub peek {
  my ($self, $length) = @_;
  return substr $self->{source}, $self->{current}, $length||1;
}

sub chomp_eof {
  my ($self, $c) = @_;
  $self->new_token(lexeme=>$c, type=>EOF);
  $self->{eof} = 1;
}

sub chomp_left_brace {
  my ($self, $c) = @_;
}

sub chomp_right_brace {
  my ($self, $c) = @_;
  $self->new_token(lexeme=>$c, type=>RIGHT_BRACE);
}
sub chomp_left_paren {
  my ($self, $c) = @_;
  $self->new_token(lexeme=>$c, type=>LEFT_PAREN);
}

sub chomp_right_paren {
  my ($self, $c) = @_;
  $self->new_token(lexeme=>$c, type=>RIGHT_PAREN);
}

sub chomp_identifier {
  my ($self, $c) = @_;
  my $column = $self->{column};
  while ($self->peek =~ /[A-Za-z0-9_]/) {
    $c .= $self->advance;
  }
  my $type;
  if ($c eq 'and') {
    $type = AND;
  }
  elsif ($c eq 'break') {
    $type = BREAK;
  }
  elsif ($c eq 'class') {
    $type = CLASS;
  }
  elsif ($c eq 'else') {
    $type = ELSE;
  }
  elsif ($c eq 'false') {
    $type = FALSE;
  }
  elsif ($c eq 'for') {
    $type = FOR;
  }
  elsif ($c eq 'if') {
    $type = IF;
  }
  elsif ($c eq 'nil') {
    $type = NIL;
  }
  elsif ($c eq 'or') {
    $type = OR;
  }
  elsif ($c eq 'print') {
    $type = PRINT;
  }
  elsif ($c eq 'return') {
    $type = RETURN;
  }
  elsif ($c eq 'super') {
    $type = SUPER;
  }
  elsif ($c eq 'this') {
    $type = THIS;
  }
  elsif ($c eq 'true') {
    $type = TRUE;
  }
  elsif ($c eq 'var') {
    $type = VAR;
  }
  elsif ($c eq 'while') {
    $type = WHILE;
  }
  else {
    $type = IDENTIFIER;
  }
  $self->new_token(lexeme=>$c, column=>$column, type=>$type);
}

sub chomp_class {
  my ($self, $word) = @_;
  my $column = $self->{column};
  while ($self->peek =~ /[\w\d]/) {
    $word .= $self->advance;
  }
  $self->new_token(lexeme=>$word, column=>$column, type=>CLASS);
}


sub chomp_number {
  my ($self, $c) = @_;
  my $column = $self->{column};
  $c .= $self->advance while ($self->peek =~ /\d/);
  if ($self->peek eq '.') {
    $c .= $self->advance;
    $c .= $self->advance while ($self->peek =~ /\d/);
  }
  $self->new_token(lexeme=>$c, type=>NUMBER, literal=>$c, column=>$column);
}

sub chomp_string {
  my ($self, $c) = @_;
  my $column = $self->{column};
  my $word;
  while ($self->peek ne '"') {
    my $next = $self->advance;
    if ($next eq "\n") {
      $self->{line}++;
    }
    elsif ($next eq '\\') { # handle \"
      $next .= $self->advance;
    }
    $word .= $next;
    $c    .= $next;
  }
  $c .= $self->advance;
  $self->new_token(lexeme=>$c, type=>STRING, literal=>$word, column=>$column);
}

sub chomp_bang {
  my ($self, $c) = @_;
  my $type = BANG;
  if ($self->peek eq '=') {
    $c .= $self->advance;
    $type = BANG_EQUAL;
  }
  $self->new_token(lexeme => $c, type => $type);
}

sub chomp_equal {
  my ($self, $c) = @_;
  my $type = EQUAL;
  if ($self->peek eq '=') {
    $c .= $self->advance;
    $type = EQUAL_EQUAL;
  }
  $self->new_token(lexeme => $c, type => $type);
}

sub chomp_greater {
  my ($self, $c) = @_;
  my $type = GREATER;
  if ($self->peek eq '=') {
    $c .= $self->advance;
    $type = GREATER_EQUAL;
  }
  $self->new_token(lexeme => $c, type => $type);
}

sub chomp_less {
  my ($self, $c) = @_;
  my $type = LESS;
  if ($self->peek eq '=') {
    $c .= $self->advance;
    $type = LESS_EQUAL;
  }
  $self->new_token(lexeme => $c, type => $type);
}

sub chomp_slash {
  my ($self, $c) = @_;
  if ($self->peek eq '/') {
    while ($self->peek ne "\n") {
      $self->advance;
    }
  }
  else {
    $self->new_token(lexeme => $c, type => SLASH);
  }
}

sub new_token {
  my ($self, %args) = @_;
  push $self->{tokens}->@*, Token->new(
    {
      literal => undef,
      column  => $self->{column},
      line    => $self->{line},
      %args,
    });
}

sub lex_error {
  my ($self, $c) = @_;
  $self->new_token(lexeme=> $c, type=>ERROR);
  push $self->{errors}->@*, [$self->{tokens}[-1], "unexpected character: $c"];
}

1;
