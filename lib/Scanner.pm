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
  elsif ($c =~ /\d/) {
    $self->chomp_number($c);
  }
  elsif ($c =~ /[A-Z]/) {
    $self->chomp_class($c);
  }
  elsif ($c eq '"') {
    $self->chomp_string($c);
  }
  else {
    $self->chomp_word($c);
  }
}

sub advance {
  my $self = shift;
  $self->{column}++;
  return substr $self->{source}, $self->{current}++, 1;
}

sub peek {
  my $self = shift;
  return substr $self->{source}, $self->{current}, 1;
}

sub chomp_eof {
  my ($self, $c) = @_;
  while (pop $self->{blocks}->@*) {
    push $self->{tokens}->@*, Token->new(
      {
        literal => 'EOF',
        lexeme  => 'EOF',
        column  => $self->{column},
        line    => $self->{line},
        type    => BLOCK_END,
      });
  }
  $self->{eof} = 1;
}

sub chomp_whitespace {
  my ($self, $space) = @_;
  $space .= $self->advance while ($self->peek eq ' ');
  return $space;
}

sub chomp_word {
  my ($self, $word) = @_;
  my $column = $self->{column};
  while ($self->peek =~ /\S/) {
    $word .= $self->advance;
  }
  push $self->{tokens}->@*, Token->new(
    {
      literal => $word,
      lexeme  => $word,
      column  => $column,
      line    => $self->{line},
      type    => WORD,
    });
}

sub chomp_class {
  my ($self, $word) = @_;
  my $column = $self->{column};
  while ($self->peek =~ /[\w\d]/) {
    $word .= $self->advance;
  }
  push $self->{tokens}->@*, Token->new(
    {
      literal => $word,
      lexeme  => $word,
      column  => $column,
      line    => $self->{line},
      type    => CLASS,
    });
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
          literal => '\n',
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
            literal => '\n',
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
          literal => '\n',
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
  while ($self->peek =~ /\d/) {
    $c .= $self->advance;
  }
  if ($self->peek eq '.') {
    $c .= $self->advance;
    while ($self->peek =~ /\d/) {
      $c .= $self->advance;
    }
    push $self->{tokens}->@*, Token->new(
      {
        literal => $c,
        lexeme  => $c,
        column  => $column,
        line    => $self->{line},
        type    => FLOAT,
      });
  }
  else {
    push $self->{tokens}->@*, Token->new(
      {
        literal => $c,
        lexeme  => $c,
        column  => $column,
        line    => $self->{line},
        type    => INTEGER,
      });
  }
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

  push $self->{tokens}->@*, Token->new(
    {
      literal => $word,
      lexeme  => $c,
      column  => $column,
      line    => $self->{line},
      type    => STRING,
    });
}

sub parse_error {
  my ($self, $message) = @_;
  push $self->{errors}->@*, [$self->{line}, $self->{column}, $message];
}

1;
