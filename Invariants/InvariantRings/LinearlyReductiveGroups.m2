--This file contains method to compute the Hilbert ideal for linearly reductive action
--TODO 6/26/20 
--1. Currently no specific TODO on this file, check code to see if any
--2. Check state of documentation
--3. Check state of tests
	  

-------------------------------------------
--- LinearlyReductiveAction methods -------
-------------------------------------------
LinearlyReductiveAction = new Type of GroupAction  

linearlyReductiveAction = method()

linearlyReductiveAction (Ideal, Matrix, PolynomialRing) :=
linearlyReductiveAction (Ideal, Matrix, QuotientRing) := LinearlyReductiveAction => (A, M, Q) -> (
    R := ambient Q;
    if not isField coefficientRing R then (error "linearlyReductiveAction: Expected the third argument to be a polynomial ring over a field.");
    if (numColumns M =!= numRows M) or (numRows M =!= #(gens R)) then (error "linearlyReductiveAction: Matrix size does not match polynomial ring.");
    if coefficientRing ring A =!= coefficientRing R then (error "linearlyReductiveAction: Group and polynomial ring not defined over same field.");
    new LinearlyReductiveAction from {
	cache => new CacheTable,
	(symbol groupIdeal) => A, 
	(symbol actionMatrix) => M, 
	(symbol ring) => Q
	}
    )


-------------------------------------------

net LinearlyReductiveAction := V -> (
    stack {(net V.ring)|" <- "|(net ring V.groupIdeal)|"/"|(net V.groupIdeal)|" via ",
	"", net V.actionMatrix}
    )

actionMatrix = method()

actionMatrix LinearlyReductiveAction := Matrix => V -> V.actionMatrix

groupIdeal = method()

groupIdeal LinearlyReductiveAction := Ideal => V -> V.groupIdeal


---------------------------------------------

-- commented out below is the original code for hilbertIdeal
-- which uses hooks
-- further below is the new version without hooks
-- FG: I didn't know how to combine options with hooks
-- so I removed hooks

-*
hilbertIdeal = method(Options => {})
	
hilbertIdeal LinearlyReductiveAction := { } >> opts -> (cacheValue (symbol hilbertIdeal)) (V -> runHooks(LinearlyReductiveAction, symbol hilbertIdeal, V))

addHook(LinearlyReductiveAction, symbol hilbertIdeal, V -> break (
    A := groupIdeal V;
    M := actionMatrix V;
    R := ambient ring V;
    U := ideal ring V;
    if (numColumns M =!= numRows M) or (numRows M =!= #(gens R)) then print "Matrix size does not match polynomial ring";
    -- first, some information about the inputs:
    n := #(gens R);
    K := coefficientRing(R);
    l := #(gens ring M);
    
    -- now make the enlarged polynomial ring we'll work in, and convert inputs to that ring
    x := local x, y := local y, z := local z;
    S := K[z_1..z_l, x_1..x_n, y_1..y_n];
    M' := sub(M, apply(l, i -> (ring M)_i => z_(i+1)));
    A' := sub(A, apply(l, i -> (ring M)_i => z_(i+1)));
    Ux' := sub(U, apply(n, i -> R_i => x_(i+1)));
    Uy' := sub(U, apply(n, i -> R_i => y_(i+1)));
    
    -- the actual algorithm follows
    J' := apply(n, i -> y_(i+1) - sum(n, j -> M'_(j,i) * x_(j+1)));
    J := A' + ideal(J') + Ux' + Uy';
    I := eliminate(apply(l, i -> z_(i+1)),J);
    II := sub(I, apply(n, i -> y_(i+1) => 0));
    
    -- return the result back in the user's input ring
    trim(sub(II, join(apply(n, i -> x_(i+1) => (ring V)_i),apply(n, i -> y_(i+1) => 0), apply(l, i -> z_(i+1) => 0))))
    ))
*-

hilbertIdeal = method(Options => {
	DegreeLimit => {},
	SubringLimit => infinity
	})

hilbertIdeal LinearlyReductiveAction := Ideal => opts -> V -> (
    if opts.DegreeLimit === {} and opts.SubringLimit === infinity and V.cache#?hilbertIdeal then (
	return V.cache#hilbertIdeal;
	);
    A := groupIdeal V;
    M := actionMatrix V;
    R := ambient ring V;
    U := ideal ring V;
    if (numColumns M =!= numRows M) or (numRows M =!= #(gens R)) then print "Matrix size does not match polynomial ring";
    -- first, some information about the inputs:
    n := #(gens R);
    K := coefficientRing(R);
    l := #(gens ring M);
    
    -- now make the enlarged polynomial ring we'll work in, and convert inputs to that ring
    x := local x, y := local y, z := local z;
    S := K[z_1..z_l, x_1..x_n, y_1..y_n, MonomialOrder=>Eliminate l];
    M' := sub(M, apply(l, i -> (ring M)_i => z_(i+1)));
    A' := sub(A, apply(l, i -> (ring M)_i => z_(i+1)));
    Ux' := sub(U, apply(n, i -> R_i => x_(i+1)));
    Uy' := sub(U, apply(n, i -> R_i => y_(i+1)));
    
    -- the actual algorithm follows
    J' := apply(n, i -> y_(i+1) - sum(n, j -> M'_(j,i) * x_(j+1)));
    J := A' + ideal(J') + Ux' + Uy';
    if opts.DegreeLimit === {} and opts.SubringLimit === infinity then (
	I := eliminate(apply(l, i -> z_(i+1)),J);
	) else (
	I = ideal selectInSubring(1,
	    gens gb(J,DegreeLimit=>opts.DegreeLimit,SubringLimit=>opts.SubringLimit)
	    );
	);
    -- I := eliminate(apply(l, i -> z_(i+1)),J);
    II := sub(I, apply(n, i -> y_(i+1) => 0));
    
    -- return the result back in the user's input ring
    -- cache if default options are used
    II = trim(sub(II, join(apply(n, i -> x_(i+1) => (ring V)_i),apply(n, i -> y_(i+1) => 0), apply(l, i -> z_(i+1) => 0))));

    if opts.DegreeLimit === {} and opts.SubringLimit === infinity then (
	V.cache#hilbertIdeal = II;
	);

    return II;
    )




