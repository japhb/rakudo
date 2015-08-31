my class IntStr is Int is Str {
    method new(Int $i, Str $s) {
        my \SELF = nqp::create(self);
        # XXX this bindattr_i fails for bigints
        nqp::bindattr_i(SELF, Int, '$!value', $i);
        nqp::bindattr_s(SELF, Str, '$!value', $s);
        SELF;
    }

    multi method Numeric(IntStr:D:) { self.Int }
    method Int(IntStr:D:) { nqp::getattr_i(self, Int, '$!value') }
    multi method Str(IntStr:D:) { nqp::getattr_s(self, Str, '$!value') }

    multi method gist(IntStr:D:) {
        "val({self.Str.perl})";
    }

    multi method perl(IntStr:D:) {
        "IntStr.new({self.Int.perl}, {self.Str.perl})";
    }
}

my class NumStr is Num is Str {
    method new(Num $n, Str $s) {
        my \SELF = nqp::create(self);
        nqp::bindattr_n(SELF, Num, '$!value', $n);
        nqp::bindattr_s(SELF, Str, '$!value', $s);
        SELF;
    }

    multi method Numeric(NumStr:D:) { self.Num }
    method Num(NumStr:D:) { nqp::getattr_n(self, Num, '$!value') }
    multi method Str(NumStr:D:) { nqp::getattr_s(self, Str, '$!value') }

    multi method gist(NumStr:D:) {
        "val({self.Str.perl})";
    }

    multi method perl(NumStr:D:) {
        "NumStr.new({self.Num.perl}, {self.Str.perl})";
    }
}

my class RatStr is Rat is Str {
    method new(Rat $r, Str $s) {
        my \SELF = nqp::create(self);
        nqp::bindattr(SELF, Rat, '$!numerator', $r.numerator);
        nqp::bindattr(SELF, Rat, '$!denominator', $r.denominator);
        nqp::bindattr_s(SELF, Str, '$!value', $s);
        SELF;
    }

    multi method Numeric(RatStr:D:) { self.Rat }
    method Rat(RatStr:D:) { Rat.new(nqp::getattr(self, Rat, '$!numerator'), nqp::getattr(self, Rat, '$!denominator')) }
    multi method Str(RatStr:D:) { nqp::getattr_s(self, Str, '$!value') }

    multi method gist(RatStr:D:) {
        "val({self.Str.perl})";
    }

    multi method perl(RatStr:D:) {
        "RatStr.new({self.Rat.perl}, {self.Str.perl})";
    }
}

my class ComplexStr is Complex is Str {
    method new(Complex $c, Str $s) {
        my \SELF = nqp::create(self);
        nqp::bindattr_n(SELF, Complex, '$!re', $c.re);
        nqp::bindattr_n(SELF, Complex, '$!im', $c.im);
        nqp::bindattr_s(SELF, Str, '$!value', $s);
        SELF;
    }

    multi method Numeric(ComplexStr:D:) { self.Complex }
    method Complex(ComplexStr:D:) { Complex.new(nqp::getattr_n(self, Complex, '$!re'), nqp::getattr_n(self, Complex, '$!im')) }
    multi method Str(ComplexStr:D:) { nqp::getattr_s(self, Str, '$!value') }

    multi method gist(ComplexStr:D:) {
        "val({self.Str.perl})";
    }

    multi method perl(ComplexStr:D:) {
        "ComplexStr.new({self.Complex.perl}, {self.Str.perl})";
    }
}

# we define cmp ops for these allomorphic types as numeric first, then Str. If
# you want just one half of the cmp, you'll need to coerce the args
multi sub infix:<cmp>(IntStr $a, IntStr $b) {
    given $a.Int cmp $b.Int {
        return $_ unless $_ === Order::Same;
        $a.Str cmp $b.Str
    }
}

multi sub infix:<cmp>(RatStr $a, RatStr $b) {
    given $a.Rat cmp $b.Rat {
        return $_ unless $_ === Order::Same;
        $a.Str cmp $b.Str
    }
}

multi sub infix:<cmp>(NumStr $a, NumStr $b) {
    given $a.Num cmp $b.Num {
        return $_ unless $_ === Order::Same;
        $a.Str cmp $b.Str
    }
}

multi sub infix:<cmp>(ComplexStr $a, ComplexStr $b) {
    given $a.Complex cmp $b.Complex {
        return $_ unless $_ === Order::Same;
        $a.Str cmp $b.Str
    }
}

# these allomorphic multis are needed to use their C<.gist>s properly, lest they
# pick the Str:D candidate.
multi sub say(IntStr:D \x) {
    my $out := $*OUT;
    $out.print: x.gist;
    $out.print-nl;
}
multi sub say(RatStr:D \x) {
    my $out := $*OUT;
    $out.print: x.gist;
    $out.print-nl;
}
multi sub say(NumStr:D \x) {
    my $out := $*OUT;
    $out.print: x.gist;
    $out.print-nl;
}
multi sub say(ComplexStr:D \x) {
    my $out := $*OUT;
    $out.print: x.gist;
    $out.print-nl;
}

multi sub note(IntStr:D \x) {
    my $err := $*ERR;
    $err.print: x.gist;
    $err.print-nl;
}
multi sub note(RatStr:D \x) {
    my $err := $*ERR;
    $err.print: x.gist;
    $err.print-nl;
}
multi sub note(NumStr:D \x) {
    my $err := $*ERR;
    $err.print: x.gist;
    $err.print-nl;
}
multi sub note(ComplexStr:D \x) {
    my $err := $*ERR;
    $err.print: x.gist;
    $err.print-nl;
}

multi sub val(*@maybevals) {
    # XXX .Parcel not needed on GLR (just .eager suffices)
    # XXX GLR would need a .List before the .map, so that the output is === compatible
    @maybevals.map({ val($_) }).eager.Parcel;
}

# XXX this multi not needed in GLR ?
multi sub val(@maybevals) {
    val(|@maybevals);
}

multi sub val(Pair $ww-thing) {
    # this is a Pair object possible in «» constructs; just pass it through. We
    # capture this specially from the below sub to avoid emitting a warning
    # whenever an affected «» construct is being processed.

    $ww-thing;
}

multi sub val(\one-thing) {
    warn "Value of type {one-thing.WHAT.perl} uselessly passed to val()";
    one-thing;
}

multi sub val(Str $maybeval) {

#`{{{{
    =begin pod

    The below subs build on one another. This mini-document is designed to
    illustrate what kinds of literals val handles, and how these mini-subs fit
    together.

    The phrase "or fails" in statements on return values means it returns
    C<Bool::False>, or some other non-number if C<Bool::False> turns out to be
    too resource-intensive for this function.

    Two generic checkers:

    =item Check for negation --- C<is-negated>
      =item2 Modifies given number (to remove sign if present)
      =item2 Returns C<1> or C<0>, to match the flag for C<nqp::radix_I>

    =item Check for oh radix prefix --- C<get-ohradix>
      =item2 Returns new radix or fails

    And the literals' structure:

    =item Bare integer --- C<just-int> --- C<42>, C<-12>, C<0xF>, etc.
      =item2 Options:
        =item3 C<:e> --- used when calling from C<science-num>
        =item3 C<:nosign> --- used when calling from C<frac-rat>
      =item2 Requires:
        =item3 C<is-negated> (unless C<:nosign>)
        =item3 C<get-ohradix> (unless C<:e>)
      =item2 Returns C<Int> or fails

    =item Radix point rational --- C<point-rat> --- C<3.2>, C<-5.4>
      =item2 Options:
        =item3 C<:adverb> --- used when calling from C<radix-adverb>
        =item3 C<:nosign> --- passed through for C<just-int>, and used in here
      =item2 Requires:
        =item3 C<just-int(:$nosign)> (for before point portion)
        =item3 C<is-negated> (unless C<:nosign>)
        =item3 C<get-ohradix> (only if C<:adverb>)
      =item2 Returns C<Rat> or fails

    =item Scientific C<Num> --- C<science-num> --- C<1e5>, C<-3.5e-2>
      =item2 Requires:
        =item3 C<point-rat> (coefficient)
        =item3 C<just-int(:e)> (exponent, base of 10 implied)
      =item2 Returns C<Num> or fails

    =item Adverbial number --- C<radix-adverb> --- C«:16<FF>», C«:11<0o7.7*8**2>», etc.
      =item2 Options:
        =item3 C<:nofrac> --- used when calling from C<frac-rat>
        =item3 C<:nosign> --- controls whether a sign can be in front of the adverb
      =item2 Requires:
        =item3 C<just-int(:nosign)> (for radix specifier, integer coeff)
        =item3 C<point-rat(:adverb, :nosign)> (non-int coefficient)
        =item3 C<radix-adverb(:nofrac, :$nosign)> (optional base in :#<> form)
        =item3 C<just-int(:$nosign)> (optional base in :#<> form)
        =item3 C<radix-adverb(:nofrac)> (optional exp in :#<> form)
        =item3 C<just-int> (optional exp in :#<> form)
      =item2 Returns:
        =item3 C<Num> if optional base and exponent;
        =item3 C<Rat> without base and exponent, non-integral number;
        =item3 C<Int> without base and exponent, integral number;
        =item3 or fails

    =item Fractional rational --- C<frac-rat> --- C«1/2», C«-3/:16<F>», etc
      =item2 Requires:
        =item3 C<radix-adverb(:nofrac)> (for :#<> form numerator)
        =item3 C<just-int> (for bare integers in numerator)
        =item3 C<radix-adverb(:nofrac, :nosign)> (for :#<> form denominator)
        =item3 C<just-int(:nosign)> (for bare integers in numerator)

    =item Complex number --- C<complex-num> --- C<1+2i>, C<-3.5+-1i>, etc
      =item2 Requires:
        =item3 C<radix-adverb>
        =item3 C<science-num>
        =item3 C<point-rat>
        =item3 C<just-int>
      =item2 Returns C<Complex> or fails
    =end pod
}}}}

    ##| checks if number is to be negated, and chops off the sign
    sub is-negated($val is rw) {
        if nqp::eqat($val, '-', 0) {
            $val = nqp::substr($val, 1);
            1
        } elsif nqp::eqat($val, '+', 0) {
            $val = nqp::substr($val, 1);
            0
        } else {
            0
        }
    }

    ##| retrieve an "oh radix" (0x, 0o, etc.), if there
    sub get-ohradix($maybeint is copy, $radix = 10) { # $radix to limit valid ohradices
        my $negated = is-negated($maybeint);
        if $radix < 34 && nqp::eqat($maybeint, '0x', 0) {
            16
        } elsif $radix < 14 && nqp::eqat($maybeint, '0d', 0) {
            10
        } elsif $radix < 25 && nqp::eqat($maybeint, '0o', 0) {
            8
        } elsif $radix < 12 && nqp::eqat($maybeint, '0b', 0) {
            2
        } else {
            False
        }
    }

    sub try-possibles($checking, *@funcs) {
        my $cand;
        for @funcs -> &trying {
            $cand = &trying($checking);
            last unless $cand === False;
        }
        $cand;
    }

    ##| processes an integer, by default decimal
    sub just-int($maybeint is copy, $radix is copy = 10, :$e = False, :$nosign = False) {
        my $negated = $nosign ?? 0 !! is-negated($maybeint);
        my $ohradix = $e ?? False !! get-ohradix($maybeint, $radix);

        $radix = $ohradix if $ohradix !=== False;

        my $startpos = 0;
        if $ohradix !=== False {
            $startpos = 2;

            # handle initial underscore, since radix_I won't
            if nqp::eqat($maybeint, '_', $startpos) {
                $startpos++;
            }
        }

        my $radresult := nqp::radix_I($radix, $maybeint, $startpos, $negated, Int);

        if nqp::atpos($radresult, 2) < nqp::chars($maybeint) {
            return False;
        }

        nqp::atpos($radresult, 0);
    }

    ##| process a Rat in "radix point" notation
    sub point-rat($mayberat is copy, $radix is copy = 10, :$nosign = False, :$adverb = False) {
        my $radixpoint = nqp::index($mayberat, '.');

        if $radixpoint == -1 {
            return False;
        }

        my $ipart = nqp::substr($mayberat, 0, $radixpoint);
        my $fpart = nqp::substr($mayberat, $radixpoint + 1);

        my $negated = $nosign ?? 0 !! is-negated($ipart);
        my $ohradix = $adverb ?? get-ohradix($mayberat, $radix) !! False;

        $radix = $ohradix if $ohradix !=== False;

        if nqp::index($fpart, '.') > -1 {
            return False;
        }

        $ipart = just-int($ipart, $radix, :$nosign, :e); # :e because we've handled the ohradix ourselves
        my $frad := nqp::radix_I($radix, $fpart, 0, 4, Int);

        if nqp::atpos($frad, 2) < nqp::chars($fpart) || $ipart === False {
            return False;
        }

        $ipart *= nqp::atpos($frad, 1);
        $ipart += nqp::atpos($frad, 0);
        $ipart *= $negated ?? -1 !! 1;

        return Rat.new($ipart, nqp::atpos($frad, 1));
    }

    ##| process a :#<> form number (:#[] NYI)
    sub radix-adverb($maybenum is copy, :$nofrac = False, :$nosign = False) {
        unless nqp::eqat($maybenum, ':', 0) || nqp::eqat($maybenum, ':', 1) {
            return False;
        }

        # get the sign, if there
        my $negated = $nosign ?? 0 !! is-negated($maybenum);

        # get the radix
        my $baseradix := nqp::radix_I(10, $maybenum, 1, 0, Int);

        if nqp::atpos($baseradix, 2) == -1 || !(2 <= nqp::atpos($baseradix, 0) <= 36) {
            return False; # wouldn't be so immediately failing when :#[] form is supported
        }

        # get start point

        my $numstart = nqp::atpos($baseradix, 2);
        my $defradix = nqp::atpos($baseradix, 0);

        if !nqp::eqat($maybenum, '<', $numstart) {
            if nqp::eqat($maybenum, '[', $numstart) {
                warn ":[] NYI for val()";
            } elsif nqp::eqat($maybenum, '(', $numstart) {
                warn ":() not supported by val()";
            }

            return False;
        }

        $numstart++;

        # get components (coeff, base, exp)

        my ($coeff, $coend, $base, $bend, $exp, $eend);

        $coend = nqp::index($maybenum, '*', $numstart);

        if $coend == -1 { # no base and exp, just coeff
            $coend = nqp::index($maybenum, '>', $numstart);

            if $coend < nqp::chars($maybenum) - 1 {
                return False;
            }

            $coeff = nqp::substr($maybenum, $numstart, $coend - $numstart);

            my $res;
            if $nofrac {
                $res = just-int($coeff, $defradix, :nosign);
            } else {
                $res = try-possibles($coeff, { just-int($_, $defradix, :nosign) }, { point-rat($_, $defradix, :nosign, :adverb) });
            }

            unless $res === False || !$negated {
                $res = -$res;
            }

            return $res;
        }

        # we know we have a Num at this point, so no fractionals allowed means
        # failure
        if $nofrac {
            return False;
        }

        # get a base and exponent

        $bend = nqp::index($maybenum, '**', $coend + 1);
        return False if $bend == -1;

        $eend = nqp::index($maybenum, '>', $bend + 1);
        return False if $eend == -1;
        return False if $eend < nqp::chars($maybenum) - 1;

        # get substrings

        $coeff = nqp::substr($maybenum, $numstart, $coend - $numstart);
        $base  = nqp::substr($maybenum, $coend + 1, $bend - $coend - 1);
        $exp   = nqp::substr($maybenum, $bend + 2, $eend - $bend - 2);

        # coefficient is at best a decimal number, base and exp can be adverbs themselves

        $coeff = try-possibles($coeff, { just-int($_ , $defradix, :nosign) },
                               { point-rat($_, $defradix, :nosign, :adverb) });
        $base = try-possibles($base, { just-int($_ , 10, :$nosign) },
                              { radix-adverb($_, :nofrac, :$nosign) });
        $exp = try-possibles($exp, &just-int, { radix-adverb($_, :nofrac) });

        if $coeff === False || $base === False || $exp === False {
            return False;
        } else {
            ($negated ?? -1 !! 1) * $coeff.Num * $base.Num ** $exp.Num;
        }
    }

    ##| Rationals in fraction form
    sub frac-rat($mayberat) {
        my $slash = nqp::index($mayberat, '/');

        if $slash == -1 {
            return False;
        }

        my $nstr = nqp::substr($mayberat, 0, $slash);
        my $dstr = nqp::substr($mayberat, $slash + 1);

        # Rat literals only allow integral numerators/denominators
        my $numer = try-possibles($nstr, &just-int, { radix-adverb($_, :nofrac) });
        my $denom = try-possibles($dstr, { just-int($_, :nosign) },
                                  { radix-adverb($_, :nofrac, :nosign) });

        if $numer === False || $denom === False {
            return False;
        } else {
            return Rat.new($numer, $denom);
        }
    }

    ##| Scientific notation Nums, or Inf/NaN
    sub science-num($maybenum) {
        my $e = nqp::index($maybenum, 'e');
        $e = nqp::index($maybenum, 'E') if $e == -1;

        if $e == -1 {
            if nqp::chars($maybenum) == 4 {
                return Inf if nqp::iseq_s($maybenum, nqp::unbox_s("+Inf"));
                return -Inf if nqp::iseq_s($maybenum, nqp::unbox_s("-Inf"));
                return NaN if nqp::iseq_s($maybenum, nqp::unbox_s("+NaN"));
                return -NaN if nqp::iseq_s($maybenum, nqp::unbox_s("-NaN"));
            } elsif nqp::chars($maybenum) == 3 {
                return Inf if nqp::iseq_s($maybenum, nqp::unbox_s("Inf"));
                return NaN if nqp::iseq_s($maybenum, nqp::unbox_s("NaN"));
            }

            return False;
        }

        my $cstr = nqp::substr($maybenum, 0, $e);
        my $estr = nqp::substr($maybenum, $e + 1);

        my $coeff = try-possibles($cstr, {just-int($_, :e)}, &point-rat);
        my $exp   = just-int($estr, :e);

        if $coeff === False || $exp === False {
            return False;
        } else {
            return $coeff.Num * 10 ** $exp.Num;
        }
    }

    ##| Complex numbers
    sub complex-num($maybecmpx) {
        unless nqp::eqat($maybecmpx, 'i', nqp::chars($maybecmpx) - 1) {
            return False;
        }

        my $escape-i = 0;
        $escape-i++ if nqp::eqat($maybecmpx, Q[\i], nqp::chars($maybecmpx) - 2);

        my $splitpos = 1;

        my $negated-im = 1;

        while $splitpos < nqp::chars($maybecmpx) {
            last if nqp::eqat($maybecmpx, '+', $splitpos);

            if nqp::eqat($maybecmpx, '-', $splitpos) {
                $negated-im = -1;
                last;
            }

            $splitpos++;
        }

        my $re;
        my $im;

        if $splitpos == nqp::chars($maybecmpx) { # purely imaginary
            my $istr = nqp::substr($maybecmpx, 0, nqp::chars($maybecmpx) - (1 + $escape-i));
            $re = 0;
            $im = try-possibles($istr, &just-int, &point-rat, &science-num, &radix-adverb);
        } else {
            my $rstr = nqp::substr($maybecmpx, 0, $splitpos);
            my $istr = nqp::substr($maybecmpx, $splitpos + 1, (nqp::chars($maybecmpx) - (1 + $escape-i)) - $splitpos - 1);

            $re = try-possibles($rstr, &just-int, &point-rat, &science-num, &radix-adverb);
            $im = try-possibles($istr, &just-int, &point-rat, &science-num, &radix-adverb);
        }

        if $re === False || $im === False {
            return False;
        }

        if $im === (NaN|Inf|-Inf) && $escape-i == 0 { # don't let NaNi or Infi work, must be NaN\i or Inf\i
            return False;
        }

        return Complex.new($re, $im * $negated-im);
    }

    #
    # And now, finally, the part where we do something
    #

    # get unboxed, trimmed string (calling .trim is at least not worse than
    # manually trimming the unboxed string ourselves, and perhaps a bit better).
    my $as-str = nqp::unbox_s($maybeval.trim);

    my $as-parsed = try-possibles($as-str, &just-int, &point-rat, &frac-rat, &science-num, &radix-adverb, &complex-num);

    if $as-parsed === False {
        return $maybeval;
    } else {
        # construct appropriate allomorphic object. We wait until the end,
        # instead of having the above inner subs make them, because the other
        # inner subs calling would just convert them back to numeric-only, and
        # make it a waste to construct an allomorphic object.
        given $as-parsed {
            when Int {
                return IntStr.new($_, $maybeval);
            }

            when Rat {
                return RatStr.new($_, $maybeval);
            }

            when Num {
                return NumStr.new($_, $maybeval);
            }

            when Complex {
                return ComplexStr.new($_, $maybeval);
            }

            default {
                die "Unknown type from val() processing: {$_.WHAT}";
            }
        }
    }
}