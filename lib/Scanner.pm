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
  elsif ($c eq ' ') {
    $self->chomp_whitespace($c);
  }
  elsif ($c eq "\n") {
    $self->chomp_newline($c);
  }
  elsif ($c eq '"') {
    $self->chomp_string($c);
  }
  elsif ($c eq '(') {
    $self->chomp_paren_open($c);
  }
  elsif ($c eq ')') {
    $self->chomp_paren_close($c);
  }
  elsif ($c =~ /\d/) {
    $self->chomp_number($c);
  }
  elsif ($c eq '.') {
    $self->chomp_method($c);
  }
  elsif ($c =~ /[A-Z]/) {
    $self->chomp_class($c);
  }
  elsif ($c =~ /[a-z]/) {
    $self->chomp_word($c);
  }
  elsif ($c eq '!') {
    $self->chomp_bang($c);
  }
  elsif ($c eq '=') {
    $self->chomp_equals($c);
  }
  elsif ($c eq '>') {
    $self->chomp_greater($c);
  }
  elsif ($c eq '<') {
    $self->chomp_less($c);
  }
  elsif ($c eq '-') {
    $self->chomp_minus($c);
  }
  elsif ($c eq '+') {
    $self->chomp_plus($c);
  }
  elsif ($c eq '/') {
    $self->chomp_slash($c);
  }
  elsif ($c eq '*') {
    $self->chomp_star($c);
  }
  else {
    $self->lex_error($c);
  }
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
  while (pop $self->{blocks}->@*) {
    $self->new_token(lexeme=>$c, type=>BLOCK_END);
  }
  $self->new_token(lexeme=>$c, type=>EOF);
  $self->{eof} = 1;
}

sub chomp_whitespace {
  my ($self, $space) = @_;
  $space .= $self->advance while ($self->peek eq ' ');
  return $space;
}

sub chomp_paren_open {
  my ($self, $c) = @_;
  $self->new_token(lexeme=>$c, type=>LEFT_PAREN);
}

sub chomp_paren_close {
  my ($self, $c) = @_;
  $self->new_token(lexeme=>$c, type=>RIGHT_PAREN);
}

sub chomp_method {
  my ($self, $c) = @_;
  my $column = $self->{column};
  while ($self->peek =~ /[A-Za-z0-9_]/) {
    $c .= $self->advance;
  }
  $self->new_token(lexeme=>$c, column=>$column, type=>METHOD);
}

sub chomp_word {
  my ($self, $c) = @_;
  my $column = $self->{column};
  while ($self->peek =~ /[A-Za-z0-9_]/) {
    $c .= $self->advance;
  }

  my $type;
  if ($c eq 'true') {
    $type = TRUE;
  }
  elsif ($c eq 'false') {
    $type = FALSE;
  }
  elsif ($c eq 'nil') {
    $type = NIL;
  }
  elsif ($c eq 'print') {
    $type = PRINT;
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

sub chomp_newline {
  my ($self, $c) = @_;
  my $column = $self->{column};
  $self->{column} = 1;

  unless ($self->peek eq "\n") {
    my $current_indent = $self->{blocks}[-1]//0;

    my $indent = length $self->chomp_whitespace('');
    if ($indent > $current_indent) {
      push $self->{blocks}->@*, $indent;
      push $self->{tokens}->@*, Token->new(
        {
          literal => undef,
          lexeme  => '\n',
          column  => $column,
          line    => $self->{line},
          type    => BLOCK_BEGIN,
        });
    }
    elsif ($indent < $current_indent) {
      do {
        pop $self->{blocks}->@*;
        push $self->{tokens}->@*, Token->new(
          {
            literal => undef,
            lexeme  => '\n',
            column  => $column,
            line    => $self->{line},
            type    => BLOCK_END,
          });
          $current_indent = $self->{blocks}[-1]//0;
      } while ($indent < $current_indent);
    }
    else {
      push $self->{tokens}->@*, Token->new(
        {
          literal => undef,
          lexeme  => '\n',
          column  => $column,
          line    => $self->{line},
          type    => STMNT_END,
        });
    }
  }
  $self->{line}++;
}

sub chomp_number {
  my ($self, $c) = @_;
  my $column = $self->{column};
  my $type = INTEGER;
  while ($self->peek =~ /\d/) {
    $c .= $self->advance;
  }
  if ($self->peek(2) =~ /^\.\d$/) {
    $type = FLOAT;
    $c .= $self->advance;
    while ($self->peek =~ /\d/) {
      $c .= $self->advance;
    }
  }
  $self->new_token(lexeme=>$c, type=>$type, literal=>$c, column=>$column);
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

sub chomp_minus {
  my ($self, $c) = @_;
  $self->new_token(lexeme => $c, type => MINUS);
}

sub chomp_plus {
  my ($self, $c) = @_;
  $self->new_token(lexeme => $c, type => PLUS);
}

sub chomp_slash {
  my ($self, $c) = @_;
  $self->new_token(lexeme => $c, type => SLASH);
}

sub chomp_star {
  my ($self, $c) = @_;
  $self->new_token(lexeme => $c, type => STAR);
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
