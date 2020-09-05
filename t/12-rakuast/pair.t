use MONKEY-SEE-NO-EVAL;
use Test;

plan 6;

is-deeply  # answer => 42
        EVAL(RakuAST::FatArrow.new(
            key => 'answer',
            value => RakuAST::IntLiteral.new(42)
        )),
        (answer => 42),
        'Fat arrow syntax forms a Pair';

is-deeply  # :r
        EVAL(RakuAST::ColonPair::True.new(
            key => 'r'
        )),
        (r => True),
        'True colonpair forms a Pair with value True';

is-deeply  # :!r
        EVAL(RakuAST::ColonPair::False.new(
            key => 'r'
        )),
        (r => False),
        'False colonpair forms a Pair with value False';

is-deeply  # :answer(42)
        EVAL(RakuAST::ColonPair::Number.new(
            key => 'answer',
            value => RakuAST::IntLiteral.new(42)
        )),
        (answer => 42),
        'Number colonpair forms a Pair with the correct Int value';

is-deeply  # :cheese<stilton>
        EVAL(RakuAST::ColonPair::Value.new(
            key => 'cheese',
            value => RakuAST::StrLiteral.new('stilton')
        )),
        (cheese => 'stilton'),
        'Value colonpair forms a Pair with the correct value';

{  # :$curry
    my $curry = 'red';
    is-deeply
            EVAL(RakuAST::ColonPair::Variable.new(
                key => 'curry',
                value => RakuAST::Var::Lexical.new('$curry')
            )),
            (curry => 'red'),
            'Variable colonpair forms a Pair that looks up the variable';
}
