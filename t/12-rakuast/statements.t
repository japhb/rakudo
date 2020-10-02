use MONKEY-SEE-NO-EVAL;
use Test;

plan 26; # Do not change this file to done-testing

my $ast;
sub ast(RakuAST::Node:D $node --> Nil) {
    $ast := $node;
    diag $ast.DEPARSE.chomp;
}

subtest 'Statement list evaluates to its final statement' => {
    my $x = 12;
    my $y = 99;

    # ++$x; ++$y
    ast RakuAST::StatementList.new(
      RakuAST::Statement::Expression.new(
        expression => RakuAST::ApplyPrefix.new(
          prefix => RakuAST::Prefix.new('++'),
          operand => RakuAST::Var::Lexical.new('$x')
        )
      ),
      RakuAST::Statement::Expression.new(
        expression => RakuAST::ApplyPrefix.new(
          prefix => RakuAST::Prefix.new('++'),
          operand => RakuAST::Var::Lexical.new('$y')
        )
      )
    );

    is-deeply EVAL($ast), 100,
      'AST: Statement list evaluates to its final statement';
    is $x, 13,
      'AST: First side-effecting statement was executed';
    is $y, 100,
      'AST: Second side-effecting statement was executed';

    is-deeply EVAL($ast.DEPARSE), 101,
      'DEPARSE: Statement list evaluates to its final statement';
    is $x, 14,
      'DEPARSE: First side-effecting statement was executed';
    is $y, 101,
      'DEPARSE: Second side-effecting statement was executed';
}

subtest 'Basic if / elsif / else structure' => {
    my ($a, $b, $c);

    # if $a { 1 }
    # elsif $b { 2 }
    # elsif $c { 3 }
    # else { 4 }
    ast RakuAST::Statement::If.new(
      condition => RakuAST::Var::Lexical.new('$a'),
      then => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::IntLiteral.new(1)
            )
          )
        )
      ),
      elsifs => [
        RakuAST::Statement::Elsif.new(
          condition => RakuAST::Var::Lexical.new('$b'),
          then => RakuAST::Block.new(
            body => RakuAST::Blockoid.new(
              RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                  expression => RakuAST::IntLiteral.new(2)
                )
              )
            )
          )
        ),
        RakuAST::Statement::Elsif.new(
          condition => RakuAST::Var::Lexical.new('$c'),
          then => RakuAST::Block.new(
            body => RakuAST::Blockoid.new(
              RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                  expression => RakuAST::IntLiteral.new(3)
                )
              )
            )
          )
        )
      ],
      else => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::IntLiteral.new(4)
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $a = $b = $c = False;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 4,
          "$type: When all conditions False, else is evaluated";

        $c = True;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 3,
          "$type: Latest elsif reachable when matched";

        $b = True;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 2,
          "$type: First elsif reachable when matched";

        $a = True;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 1,
          "$type: When the main condition is true, the then block is picked";
    }
}

subtest 'simple if evaluation' => {
    my $a;

    # if $a { 1 }
    ast RakuAST::Statement::If.new(
      condition => RakuAST::Var::Lexical.new('$a'),
      then => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::IntLiteral.new(1)
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $a = True;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 1,
          "$type: When simple if with no else has true condition";

        $a = False;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Empty,
          "$type: When simple if with no else has false condition";
    }
}

subtest 'Basic with / orwith / else structure' => {
    my ($a, $b, $c);

    # with $a -> $x { 1 }
    # orwith -> $x { 2 }
    # orwith -> $x { 3 }
    # else -> $x { 4 }
    ast RakuAST::Statement::With.new(
      condition => RakuAST::Var::Lexical.new('$a'),
      then => RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
          parameters => (
            RakuAST::Parameter.new(
              target => RakuAST::ParameterTarget::Var.new('$x')
            ),
          )
        ),
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::IntLiteral.new(1)
            )
          )
        )
      ),
      elsifs => [
        RakuAST::Statement::Orwith.new(
          condition => RakuAST::Var::Lexical.new('$b'),
          then => RakuAST::PointyBlock.new(
            signature => RakuAST::Signature.new(
              parameters => (
                RakuAST::Parameter.new(
                  target => RakuAST::ParameterTarget::Var.new('$x')
                ),
              )
            ),
            body => RakuAST::Blockoid.new(
              RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                  expression => RakuAST::IntLiteral.new(2)
                )
              )
            )
          )
        ),
        RakuAST::Statement::Orwith.new(
          condition => RakuAST::Var::Lexical.new('$c'),
            then => RakuAST::PointyBlock.new(
              signature => RakuAST::Signature.new(
                parameters => (
                  RakuAST::Parameter.new(
                    target => RakuAST::ParameterTarget::Var.new('$x')
                  ),
                )
              ),
            body => RakuAST::Blockoid.new(
              RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                  expression => RakuAST::IntLiteral.new(3)
                )
              )
            )
          )
        )
      ],
      else => RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
          parameters => (
            RakuAST::Parameter.new(
              target => RakuAST::ParameterTarget::Var.new('$x')
            ),
          )
        ),
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::IntLiteral.new(4)
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $a = $b = $c = Nil;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 4,
          "$type: When all conditions undefined, else is evaluated";

        $c = False;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 3,
          "$type: Latest orwith reachable when matched";

        $b = False;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 2,
          "$type: First orwith reachable when matched";

        $a = False;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 1,
          "$type: When the main condition is defined, the then block is picked";
    }
}

subtest 'simple with evaluation' => {
    my $a;

    # with $a -> $x { 1 }
    ast RakuAST::Statement::With.new(
      condition => RakuAST::Var::Lexical.new('$a'),
      then => RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
          parameters => (
            RakuAST::Parameter.new(
              target => RakuAST::ParameterTarget::Var.new('$x')
            ),
          )
        ),
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::IntLiteral.new(1)
            )
          )
        )
      )
    );
    for 'AST', 'DEPARSE' -> $type {
        $a = False;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 1,
          "$type: When simple when with no else has defined condition";

        $a = Nil;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Empty,
          "$type: When simple with if with no else has undefined condition";
    }
}

subtest 'with topicalizes in the body' => {
    # with $a { $_ } else { $_ }
    ast RakuAST::Statement::With.new(
      condition => RakuAST::Var::Lexical.new('$a'),
      then => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::Var::Lexical.new('$_')
            )
          )
        )
      ),
      else => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::Var::Lexical.new('$_')
            )
          )
        )
      )
    );
    for 'AST', 'DEPARSE' -> $type {
        my $a = 42;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 42,
          "$type: with topicalizes in the body";

        $a = Int;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Int,
          "$type: with topicalizes in the else body too";
    }
}

subtest 'simple unless with a false condition' => {
    my $x = False;
    my $y = 9;

    # unless $x { ++$y }
    ast RakuAST::Statement::Unless.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('++'),
                operand => RakuAST::Var::Lexical.new('$y')
              )
            )
          )
        )
      )
    );

    is-deeply EVAL($ast), 10,
      'AST: unless block with a false condition evaluates to its body';
    is $y, 10, 'AST: Side-effect of the body was performed';

    is-deeply EVAL($ast.DEPARSE), 11,
      'DEPARSE: unless block with a false condition evaluates to its body';
    is $y, 11, 'DEPARSE: Side-effect of the body was performed';
}

subtest 'simple unless with a false condition' => {
    my $x = True;
    my $y = 9;

    # unless $x { ++$y }
    ast RakuAST::Statement::Unless.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix  => RakuAST::Prefix.new('++'),
                operand => RakuAST::Var::Lexical.new('$y')
              )
            )
          )
        )
      )
    );

    is-deeply EVAL($ast), Empty,
      'AST: unless block with a false condition evaluates to Empty';
    is $y, 9, 'AST: Side-effect of the body was not performed';

    is-deeply EVAL($ast.DEPARSE), Empty,
      'DEPARSE: unless block with a false condition evaluates to Empty';
    is $y, 9, 'DEPARSE: Side-effect of the body was not performed';
}

subtest 'simple without with an undefined condition' => {
    my $x = Nil;
    my $y = 9;

    # without $x { $y++ }
    ast RakuAST::Statement::Without.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPostfix.new(
                postfix => RakuAST::Postfix.new('++'),
                operand => RakuAST::Var::Lexical.new('$y')
              )
            )
          )
        )
      )
    );

    is-deeply EVAL($ast), 9,
      'AST: without block with an undefined object evaluates to its body';
    is $y, 10, 'AST: Side-effect of the body was performed';

    is-deeply EVAL($ast.DEPARSE), 10,
      'DEPARSE: without block with an undefined object evaluates to its body';
    is $y, 11, 'DEPARSE: Side-effect of the body was performed';
}

subtest 'simple without with a defined condition' => {
    my $x = True;
    my $y = 9;

    # without $x { ++$y }
    ast RakuAST::Statement::Without.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('++'),
                operand => RakuAST::Var::Lexical.new('$y')
              )
            )
          )
        )
      )
    );

    is-deeply EVAL($ast), Empty,
      'AST: An without block with a defined object evaluates to Empty';
    is $y, 9, 'AST: Side-effect of the body was not performed';

    is-deeply EVAL($ast.DEPARSE), Empty,
      'DEPARSE: An without block with a defined object evaluates to Empty';
    is $y, 9, 'DEPARSE: Side-effect of the body was not performed';
}

subtest 'simple without with an undefined condition' => {
    my $x = Cool;

    # without $x { $_ }
    ast RakuAST::Statement::Without.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(body =>
        RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::Var::Lexical.new('$_')
            )
          )
        )
      )
    );

    for 'AST', EVAL($ast), 'DEPARSE', EVAL($ast.DEPARSE) -> $type, $result {
        is-deeply $result, Cool,
          "$type: without block sets the topic";
    }
}

subtest 'While loop at statement level evaluates to Nil' => {
    my $x;

    # while $x { --$x }
    ast RakuAST::Statement::Loop::While.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('--'),
                operand => RakuAST::Var::Lexical.new('$x')
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $x = 5;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: while loop at statement level evaluates to Nil";
        is-deeply $x, 0, "$type: Loop variable was decremented to zero";
    }
}

subtest 'Until loop at statement level evaluates to Nil' => {
    my $x;

    # until !$x { --$x }
    ast RakuAST::Statement::Loop::Until.new(
      condition => RakuAST::ApplyPrefix.new(
        prefix => RakuAST::Prefix.new('!'),
        operand => RakuAST::Var::Lexical.new('$x')
      ),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('--'),
                operand => RakuAST::Var::Lexical.new('$x')
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $x = 5;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: until loop at statement level evaluates to Nil";
        is-deeply $x, 0, "$type: Loop variable was decremented to zero";
    }
}

subtest 'Repeat while loop at statement level evaluates to Nil' => {
    my $x;

    # repeat { --$x } while $x
    ast RakuAST::Statement::Loop::RepeatWhile.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('--'),
                operand => RakuAST::Var::Lexical.new('$x')
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $x = 5;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: repeat until loop at statement level evaluates to Nil";
        is-deeply $x, 0, "$type: loop variable decremented to 0";
    }
}

subtest 'Repeat until loop at statement level evaluates to Nil' => {
    my $x;

    # repeat { --$x } until $x
    ast RakuAST::Statement::Loop::RepeatUntil.new(
      condition => RakuAST::Var::Lexical.new('$x'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('--'),
                operand => RakuAST::Var::Lexical.new('$x')
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $x = 0;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: repeat until loop at statement level evaluates to Nil";
        is-deeply $x, -1, "$type: loop ran once";
    }
}

subtest 'Loop block with setup and increment expression' => {
    my $count;

    # loop (my $i = 9; $i; --$i) { ++$count }
    ast RakuAST::Statement::Loop.new(
      setup => RakuAST::VarDeclaration::Simple.new(
        name => '$i',
        initializer => RakuAST::Initializer::Assign.new(
          RakuAST::IntLiteral.new(9)
        )
      ),
      condition => RakuAST::Var::Lexical.new('$i'),
      increment => RakuAST::ApplyPrefix.new(
        prefix => RakuAST::Prefix.new('--'),
        operand => RakuAST::Var::Lexical.new('$i')
      ),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('++'),
                operand => RakuAST::Var::Lexical.new('$count')
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $count = 0;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: loop with setup and increment evaluates to Nil";
        is-deeply $count, 9, "$type: loop ran as expected";
    }
}

subtest 'Statement level for loop' => {
    my $count;

    # for 2 .. 7 -> $x { ++$count }
    ast RakuAST::Statement::For.new(
      source => RakuAST::ApplyInfix.new(
        left => RakuAST::IntLiteral.new(2),
        infix => RakuAST::Infix.new('..'),
        right => RakuAST::IntLiteral.new(7)
      ),
      body => RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
          parameters => (
            RakuAST::Parameter.new(
              target => RakuAST::ParameterTarget::Var.new('$x')
            ),
          )
        ),
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyPrefix.new(
                prefix => RakuAST::Prefix.new('++'),
                operand => RakuAST::Var::Lexical.new('$count')
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $count = 0;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: for loop evaluates to Nil";
        is-deeply $count, 6, "$type: loop ran with expected number of times";
    }
}

subtest 'for loop with explicit iteration variable' => {
    my $total;

    # for 2 .. 7 -> $x { $total = $total + $x }
    ast RakuAST::Statement::For.new(
      source => RakuAST::ApplyInfix.new(
        left => RakuAST::IntLiteral.new(2),
        infix => RakuAST::Infix.new('..'),
        right => RakuAST::IntLiteral.new(7)
      ),
      body => RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
          parameters => (
            RakuAST::Parameter.new(
              target => RakuAST::ParameterTarget::Var.new('$x')
            ),
          )
        ),
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyInfix.new(
                left => RakuAST::Var::Lexical.new('$total'),
                infix => RakuAST::Infix.new('='),
                right => RakuAST::ApplyInfix.new(
                  left => RakuAST::Var::Lexical.new('$total'),
                  infix => RakuAST::Infix.new('+'),
                  right => RakuAST::Var::Lexical.new('$x')
                )
              )
            )
          )
        )
      )
    );

    my $sum = (2..7).sum;
    for 'AST', 'DEPARSE' -> $type {
        $total = 0;

        $type eq 'AST' ?? EVAL($ast) !! EVAL($ast.DEPARSE);
        is-deeply $total, $sum, "$type: correct value in iteration variable";
    }
}

subtest 'Statement level for loop with implicit topic' => {
    my $total = 0;

    # for 2 .. 7 { $total = $total + $_ }
    ast RakuAST::Statement::For.new(
      source => RakuAST::ApplyInfix.new(
        left => RakuAST::IntLiteral.new(2),
        infix => RakuAST::Infix.new('..'),
        right => RakuAST::IntLiteral.new(7)
      ),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::ApplyInfix.new(
                left => RakuAST::Var::Lexical.new('$total'),
                infix => RakuAST::Infix.new('='),
                right => RakuAST::ApplyInfix.new(
                  left => RakuAST::Var::Lexical.new('$total'),
                  infix => RakuAST::Infix.new('+'),
                  right => RakuAST::Var::Lexical.new('$_')
                )
              )
            )
          )
        )
      )
    );

    my $sum = (2..7).sum;
    for 'AST', 'DEPARSE' -> $type {
        $total = 0;

        $type eq 'AST' ?? EVAL($ast) !! EVAL($ast.DEPARSE);
        is-deeply $total, $sum, "$type: correct value in implicit topic";
    }
}

subtest 'given with explicit signature' => {
    # given $a -> $x { $x }
    ast RakuAST::Statement::Given.new(
      source => RakuAST::Var::Lexical.new('$a'),
      body => RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
          parameters => (
            RakuAST::Parameter.new(
              target => RakuAST::ParameterTarget::Var.new('$x')
            ),
          )
        ),
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::Var::Lexical.new('$x')
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        my $a = 'concrete';
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 'concrete',
          "$type: given topicalizes on the source (signature)";

        $a = Str;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Str,
          "$type: given topicalizes even an undefined source (signature)";
    }
}

subtest 'given with implicit signature' => {
    # given $a { $_ }
    ast RakuAST::Statement::Given.new(
      source => RakuAST::Var::Lexical.new('$a'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new(
              expression => RakuAST::Var::Lexical.new('$_')
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        my $a = 'concrete';
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 'concrete',
          "$type: given topicalizes on the source (implicit)";

        $a = Str;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Str,
          "$type: given topicalizes even an undefined source (implicit)";
    }
}

subtest 'given with when and default' => {
    # given $a { when 2 { "two" } when 3 { "three" } default { "another" } }
    ast RakuAST::Statement::Given.new(
      source => RakuAST::Var::Lexical.new('$a'),
      body => RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
          RakuAST::StatementList.new(
            RakuAST::Statement::When.new(
              condition => RakuAST::IntLiteral.new(2),
              body => RakuAST::Block.new(
                body => RakuAST::Blockoid.new(
                   RakuAST::StatementList.new(
                     RakuAST::Statement::Expression.new(
                       expression => RakuAST::StrLiteral.new('two')
                    )
                  )
                )
              )
            ),
            RakuAST::Statement::When.new(
              condition => RakuAST::IntLiteral.new(3),
              body => RakuAST::Block.new(
                body => RakuAST::Blockoid.new(
                  RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                      expression => RakuAST::StrLiteral.new('three')
                    )
                  )
                )
              )
            ),
            RakuAST::Statement::Default.new(
              body => RakuAST::Block.new(
                body => RakuAST::Blockoid.new(
                  RakuAST::StatementList.new(
                    RakuAST::Statement::Expression.new(
                      expression => RakuAST::StrLiteral.new('another')
                    )
                  )
                )
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        my $a = 2;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 'two',
          "$type: first when statement matching gives correct result";

        $a = 3;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 'three',
          "$type: second when statement matching gives correct result";

        $a = 4;
        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), 'another',
          "$type: no when statement giving default";
    }
}

subtest 'Block with CATCH/default handles exception and evalutes to Nil' => {
    my $handled;

    # { die "oops"; CATCH { $handled++ } }
    ast RakuAST::Block.new(
      body => RakuAST::Blockoid.new(
        RakuAST::StatementList.new(
          RakuAST::Statement::Expression.new(
            expression => RakuAST::Call::Name.new(
              name => RakuAST::Name.from-identifier('die'),
              args => RakuAST::ArgList.new(RakuAST::StrLiteral.new('oops'))
            )
          ),
          RakuAST::Statement::Catch.new(
            body => RakuAST::Block.new(
              body => RakuAST::Blockoid.new(
                RakuAST::StatementList.new(
                  RakuAST::Statement::Default.new(
                    body => RakuAST::Block.new(
                      body => RakuAST::Blockoid.new(
                        RakuAST::StatementList.new(
                          RakuAST::Statement::Expression.new(
                            expression => RakuAST::ApplyPostfix.new(
                              operand => RakuAST::Var::Lexical.new('$handled'),
                              postfix => RakuAST::Postfix.new('++')
                            )
                          )
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        $handled = 0;

        is-deeply EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE), Nil,
          "$type: block with CATCH/default handles exception, evalutes to Nil";
        is-deeply $handled, 1, "$type: the exception handler ran once";
        is $!, 'oops', "$type: \$! in the outer scope has the exception";
    }
}

subtest 'Exception is rethrown if unhandled' => {
    # { die "gosh"; CATCH { } }
    ast RakuAST::Block.new(
      body => RakuAST::Blockoid.new(
        RakuAST::StatementList.new(
          RakuAST::Statement::Expression.new(
            expression => RakuAST::Call::Name.new(
              name => RakuAST::Name.from-identifier('die'),
              args => RakuAST::ArgList.new(RakuAST::StrLiteral.new('gosh'))
            )
          ),
          RakuAST::Statement::Catch.new(
            body => RakuAST::Block.new(
              body => RakuAST::Blockoid.new(
                RakuAST::StatementList.new
              )
            )
          )
        )
      )
    );

    for 'AST', 'DEPARSE' -> $type {
        throws-like { EVAL($type eq 'AST' ?? $ast !! $ast.DEPARSE) },
          X::AdHoc,
          message => /gosh/,
          "$type: exception is rethrown if unhandled";
    }
}

# This test calls an imported `&ok` to check the `use` works; the test plan
# verifies that it really works.
{
    sub ok(|) { die "Imported ok was not used" };

    # use Test; ok 1, "use statement works"
    ast RakuAST::StatementList.new(
      RakuAST::Statement::Use.new(
        module-name => RakuAST::Name.from-identifier('Test')
      ),
      RakuAST::Statement::Expression.new(
        expression => RakuAST::Call::Name.new(
          name => RakuAST::Name.from-identifier('ok'),
          args => RakuAST::ArgList.new(
            RakuAST::IntLiteral.new(1),
            RakuAST::StrLiteral.new('use statements works')
          )
        )
      )
    );

    # EVALling produces test output
    EVAL($ast);
    EVAL($ast.DEPARSE);
}

# vim: expandtab shiftwidth=4
