
newPackage(
        "RandomPointsOld",
    	Version => "1.5",
    	Date => "July 2nd, 2021",
    	Authors => {
	     {Name => "Sankhaneel Bisui", Email => "sbisu@tulane.edu", HomePage=>"https://sites.google.com/view/sankhaneelbisui/home"},
	     {Name=> "Thai Nguyen", Email =>"tnguyen11@tulane.edu", HomePage=>"https://sites.google.com/view/thainguyenmath "},
	     {Name=>"Karl Schwede", Email=>"schwede@math.utah.edu", HomePage=>"https://www.math.utah.edu/~schwede/" },
	     {Name => "Sarasij Maitra", Email => "sm3vg@virginia.edu", HomePage => "https://sarasij93.github.io/"},
	     {Name => "Zhan Jiang", Email => "zoeng@umich.edu", HomePage => "http://www-personal.umich.edu/~zoeng/"}
	     },
    	Headline => "find a point in a given variety over a finite field",
        PackageImports => {"SwitchingFields", "MinimalPrimes", "ConwayPolynomials"}, 
		DebuggingMode => true, 
		Reload=>false,
		AuxiliaryFiles => false -- set to true if package comes with auxiliary files
    	)

-- Any symbols or functions that the user is to have access to
-- must be placed in one of the following two lists
export {
	"genericProjection", --documented, tested
	"projectionToHypersurface", --documented, tested    
	"randomCoordinateChange", --documented, tested
	"randomPoints", 
    "geometricPointsNew",
    "rationalPointsNew",
    "linearIntersectionNew",
    "randomPointViaMultiplicationTableNew",
	"extendIdealByNonZeroMinor",
	"findANonZeroMinor",
    "verifyPoint",
    "verifyDimZero",
    --"randomPointViaLinearIntersection", --these are here for debugging purposes
    --"randomPointViaLinearIntersectionOld", --these are here for debugging purposes
    "getRandomLinearForms", --here for debugging purposes    
    "dimViaBezout",    
    --"dimViaBezoutHomogeneous",    
    --"dimViaBezoutNonhomogeneous", 
	"Codimension",
	"MaxCoordinatesToReplace",
    "MaxCoordinatesToTrivialize",
    "Replacement",
    "Full", 
    "Trinomial",
    "Default", --a valid value for [RandomPoint, Strategy]
	"BruteForce", --a valid value for [RandomPoint, Strategy], documented, 
    "GenericProjection",  --a valid value for [RandomPoint, Strategy]
    "HybridProjectionIntersection", --a valid value for [RandomPoint, Strategy]
    "LinearIntersection",  --a valid value for [RandomPoint, Strategy]
    "MultiplicationTable", --a valid value for [RandomPoint,Strategy]
	"ProjectionAttempts", --used in the GenericProjection strategy
    "IntersectionAttempts", --used in the LinearIntersection strategy
    "ExtendField", --used in GenericProjection and LinearIntersection strategy
    "DimensionFunction", --
    "PointCheckAttempts",
    "MinorPointAttempts",
    "MinimumFieldSize",
    "DecompositionStrategy",
    "DimensionIntersectionAttempts",
    "NumThreadsToUse" -- used in the BruteForce strategy
    }
exportMutable {}

installMinprimes();

--this appears to need to be here, otherwise the options don't realize dimViaBezout is a function, it thinks its a symbol.
dimViaBezout=method(Options => {Verbose => false, Homogeneous => null, DimensionIntersectionAttempts => null, MinimumFieldSize => 200});

optRandomPoints := {
    Strategy=>Default, 
    Homogeneous => true,  
    MaxCoordinatesToReplace => 1, 
    MaxCoordinatesToTrivialize => infinity,
    Replacement => Binomial,
    Codimension => null,
    IntersectionAttempts => 20,
    ProjectionAttempts => 0,
    ExtendField => false,
    PointCheckAttempts => 0,
    DecompositionStrategy => null,
    NumThreadsToUse => 1,
    DimensionFunction => dimViaBezout,
    Verbose => false
};

optFindANonZeroMinor := optRandomPoints | {MinorPointAttempts => 5} | {ExtendField => true}

optCoorindateChange := {
    Verbose => false, 
    Homogeneous=>true, 
    Replacement=>Full, 
    MaxCoordinatesToReplace => infinity
};

optProjectionToHypersurface := {
    Codimension => null,
    Verbose => false, 
    Homogeneous=>true, 
    Replacement=>Binomial, 
    MaxCoordinatesToReplace => infinity
};

pointToIdeal = method(Options =>{Homogeneous => false});

pointToIdeal(Ring, List) := opts -> (R1, L1) -> (
        if (opts.Homogeneous == false) then (
        genList := gens R1;
        return ideal( apply(#genList, i->genList#i - (sub(L1#i, R1)) ));
        );
);

idealToPoint = method(Options => {Homogeneous => false});

idealToPoint(Ideal) := opts -> (I1) -> (
    if (opts.Homogeneous == false) then (
        genList := gens ring I1;
        return apply(genList, s -> s%I1);
    )
);

--this function was taken directly from an internal function in RationalPoints.m2 by Nathaniel Stapleton
fieldElements = (k) -> (
     J := ideal k;
     p := char k;
     els := {};
     galoisfield := class k === GaloisField;
     if galoisfield then (
          x := k.PrimitiveElement; --sometimes k_0 is not the primitive element ie. GF 9
          e := 1;
          b := 0;
          els = els|{0};
          while b != 1 do (
               b = x^e;
               e = e+1;
               els = els | {b};
               );
          );
     if not galoisfield and char ring J != 0 then (
     	  d := (degree((flatten entries gens J)_0))_0;
     	  a := (gens k)_0;
          coeffs := toList ((set toList (0..p-1)) ^** (d));
     	  for i to # coeffs - 1 do (
               x := 0;
               for j to d-1 do (
               	    x = x+coeffs_i_j*a^j;
               	    );
               els = els | {x};
               );
          );
     if not galoisfield and char ring J == 0 then els = toList (0..p-1);
     return els;
     );



  --Function to create a random point
createRandomPoints= method(TypicalValue => List, Options => {})
createRandomPoints(Ideal):=List => opts->(I1) ->(
    noVar := #generators ring I1;
    K:=coefficientRing ring (I1);
    L:=toList apply(noVar, i ->random(K));
    return L )


randomCoordinateChange = method(Options=>optCoorindateChange);

randomCoordinateChange(Ring) := opts -> (R1) -> (
    if (debugLevel > 0) or (opts.Verbose) then print "randomCoordinateChange: starting.";
    local phi;
    if not class R1 === PolynomialRing then error "randomCoordinateChange: expected a polynomial ring";
    myMon := monoid R1;
    S1 := (coefficientRing R1)(myMon);
    d1 := #gens R1;
    local genList;
    if (opts.Replacement == Binomial) then (
        genList = getRandomLinearForms(R1, {0, max(d1 - opts.MaxCoordinatesToReplace, 0), 0, min(d1, opts.MaxCoordinatesToReplace),0, 0}, Homogeneous => opts.Homogeneous, Verbose=>opts.Verbose, Verify=>true); )
    else if (opts.Replacement == Full) then (
        genList = getRandomLinearForms(R1, {0, max(d1 - opts.MaxCoordinatesToReplace, 0), 0, 0, 0, min(d1, opts.MaxCoordinatesToReplace)}, Homogeneous => opts.Homogeneous, Verbose=>opts.Verbose, Verify=>true); );
--    genList = random apply(genCount, t -> if (t < opts.MaxCoordinatesToReplace) then replacementFunction(genList#t) else genList#t);
    return map(R1, S1, genList);
);


genericProjection = method(Options=>optCoorindateChange);

genericProjection(Ideal) := opts -> (I1) -> (
    return genericProjectionByKernel(1, I1, opts);
);

genericProjection(ZZ, Ideal) := opts -> (n1, I1) -> (
    return genericProjectionByKernel(n1, I1, opts);
);

--this code is based upon randomKRationalPoint
genericProjectionOriginal = method(Options=>optCoorindateChange);

genericProjectionOriginal(ZZ, Ideal) := opts -> (n1, I1) -> (
        if (debugLevel > 0) or (opts.Verbose) then print concatenate("genericProjection (dropping ", toString(n1), " dimension):  Starting, Replacement =>", toString(opts.Replacement), ", MaxCoordinatesToReplace => ", toString(opts.MaxCoordinatesToReplace));
        R1 := ring I1;
        psi := randomCoordinateChange(R1, opts);
        flag := true;
        local psiInv;
        while (flag) do (
            try psiInv = inverse(psi) then (flag = false) else (psi = randomCoordinateChange(R1, opts));
        );
        S1 := source psi;
        I2 := psiInv(I1);
        if (n1 <= 0) then return(psi, I2); --if we don't actually want to project
        kk:=coefficientRing R1;
        local Re;
        local Rs;
        Re=kk(monoid[apply(dim S1,i->S1_i), MonomialOrder => Eliminate n1]);
        rs:=first (entries selectInSubring(1,vars Re));
        Rs=kk(monoid[rs]);
        f:=ideal substitute(selectInSubring(1, generators gb substitute(I2,Re)),Rs);
        phi := map(S1, Rs);
        return(psi*phi, f);
);

--using the SubringLimit option, as in Cremona.
genericProjectionByKernel = method(Options=>optCoorindateChange);

genericProjectionByKernel(ZZ, Ideal) := opts -> (n1, I1) -> (
    if (debugLevel > 0) or (opts.Verbose) then print concatenate("genericProjectionByKernel (dropping ", toString(n1), " dimension):  Starting, Replacement =>", toString(opts.Replacement), ", MaxCoordinatesToReplace => ", toString(opts.MaxCoordinatesToReplace));
    R1 := ring I1;
    local psi;
    if not class R1 === PolynomialRing then error "genericProjectionByKernel: expected an ideal in a polynomial ring";
    if (n1 <= 0) then( --if we don't want to project
        return(map(R1, R1), I1); --if we don't actually want to project
    ); 
    kk:=coefficientRing R1;
    myVars := drop(gens R1, n1);
    Rs := kk(monoid[myVars]);
    d2 := #myVars;
    local genList;
    if (opts.Replacement == Binomial) then (
        genList = getRandomLinearForms(R1, {0, max(d2 - opts.MaxCoordinatesToReplace, 0), 0, min(d2, opts.MaxCoordinatesToReplace), 0, 0}, Homogeneous => opts.Homogeneous, Verbose=>opts.Verbose, Verify=>true); )
    else if (opts.Replacement == Full) then (
        genList = getRandomLinearForms(R1, {0, max(d2 - opts.MaxCoordinatesToReplace, 0), 0, 0, 0, min(d2, opts.MaxCoordinatesToReplace)}, Homogeneous => opts.Homogeneous, Verbose=>opts.Verbose, Verify=>true); );
--    genList = random apply(genCount, t -> if (t < opts.MaxCoordinatesToReplace) then replacementFunction(genList#t) else genList#t);
    psi = map(R1, Rs, genList);
    myMap := map(R1/I1, Rs, genList);
    K2 := ker(myMap);
    return(psi, K2);
);

genericProjection(ZZ, Ring) := opts -> (n1, R1) -> (
    J1 := ideal R1;
    l1 := genericProjection(n1, J1, opts);
    if (class R1 === PolynomialRing) then (
        return (l1#0, source (l1#0));
    )
    else (
        J2 := l1#1;
        S1 := source(l1#0);
        newMap := map(R1, S1/J2, matrix(l1#0));
        return (newMap, source newMap);
    );
);

genericProjection(Ring) := opts -> (R1) -> (
    return genericProjection(1, R1, opts);
);

projectionToHypersurface = method(Options => optProjectionToHypersurface);
-*
projectionToHypersurface(Ideal) := opts -> (I1) -> (
        local c1;
        if (opts.Codimension === null) then (
            c1 = codim I1;
        ) else (c1 = opts.Codimension);
        return genericProjection(c1-1, I1, Homogeneous => opts.Homogeneous, MaxCoordinatesToReplace => opts.MaxCoordinatesToReplace, Replacement => opts.Replacement, Verbose=>opts.Verbose);
);*-

projectionToHypersurface(Ring) := opts -> (R1) -> (
    LO := projectionToHypersurface(ideal R1, opts);
    phi := map(R1, (source (LO#0))/(LO#1), matrix (LO#0) );
    return (phi, source phi);
);

--projectionToHypersurfaceV2 = method(Options=>optProjectionToHypersurface);

projectionToHypersurface(Ideal) := opts -> (I1) -> (
    local c1;
    R1 := ring I1;
    if (class R1 =!= PolynomialRing) then error "projectionToHypersurface:  expected an ideal in a polynomial ring.";
    
    if (opts.Codimension === null) then (
        c1 = codim I1;
    ) else (c1 = opts.Codimension);
    if (c1 <= 1) then return (map(R1, R1), I1); --its already a hypersurface
    if (c1 == infinity) then return (map(R1, R1), I1); --it's the unit ideal, and hence also a hypersurface
    n1 := c1-1;
    
    --build the target ring
    kk:=coefficientRing R1;
    myVars := drop(gens R1, n1);
    Rs := kk(monoid[myVars]);
    d2 := #myVars;
    
    --build the replacement map
    local genList;
    if (opts.Replacement == Binomial) then (
        genList = getRandomLinearForms(R1, {0, max(d2 - opts.MaxCoordinatesToReplace, 0), 0, min(d2, opts.MaxCoordinatesToReplace), 0, 0}, Homogeneous => opts.Homogeneous, Verbose=>opts.Verbose, Verify=>true); )
    else if (opts.Replacement == Full) then (
        genList = getRandomLinearForms(R1, {0, max(d2 - opts.MaxCoordinatesToReplace, 0), 0, 0, 0, min(d2, opts.MaxCoordinatesToReplace)}, Homogeneous => opts.Homogeneous, Verbose=>opts.Verbose, Verify=>true); );
--    genList = random apply(genCount, t -> if (t < opts.MaxCoordinatesToReplace) then replacementFunction(genList#t) else genList#t);
    psi := map(R1, Rs, genList);
    myMap := map(R1/I1, Rs, genList);
    J1 := ker(myMap, SubringLimit=>1);
    return (psi, J1);
);


-*
projectionToHypersurface(Ideal) := opts -> (I1) -> (
	local c1;
	if (opts.Codimension === null) then (
		c1 = codim I1;
	) else (c1 = opts.Codimension);
	local curMap;
	tempList := genericProjection(I1, Homogeneous => opts.Homogeneous, MaxCoordinatesToReplace => opts.MaxCoordinatesToReplace);
	assert(target (tempList#0) === ring I1);
	if (c1 == 2) then (
		return tempList; --if we are done, stop
	);
	assert(source (tempList#0) === ring (tempList#1));
	--otherwise recurse
	tempList2 := projectionToHypersurface(tempList#1, Hoxmogeneous => opts.Homogeneous, MaxCoordinatesToReplace => opts.MaxCoordinatesToReplace, Codimension=>c1-1);
	assert(target(tempList2#0) === ring (tempList#1));
	return ((tempList#0)*(tempList2#0), tempList2#1);
);
*-

--this function just switches one strategy in an option table for another
switchStrategy := (opts, newStrat) -> (
    tempHashTable := new MutableHashTable from opts;
    tempHashTable#Strategy = newStrat;
    return new OptionTable from tempHashTable;
);

verifyPoint = method(Options => optRandomPoints);

verifyPoint(List, List) := opts -> (finalPoint, idealList) ->(
    verifyPoint(finalPoint, ideal idealList)
);

verifyPoint(List, Ideal) := opts -> (finalPoint, I1) -> (
    if (opts.Homogeneous) then( 
        if (all(finalPoint, t -> t == 0)) then return false;
    );
    if (#finalPoint > 0) then (
        S1 := ring finalPoint#0;
        if (any(first entries gens I1, tt -> evalAtPoint(S1, tt, finalPoint) != 0)) then (
            if (opts.Verbose or debugLevel > 0) then print "verifyPoint: found a point that is not on the variety, if not using a projection strategy, this may indicate a problem.";
            return false;
        );
    )
    else return false;
    return true;
);


saturateInGenericCoordinates=method(Options => {Replacement=>Binomial})
saturateInGenericCoordinates(Ideal):= opts -> I1 -> (
    local x;
    S1 := ring I1;
    --x:=random(0, S1)*random(1, S1) + random(1, S1);
    if (opts.Replacement == Monomial) then x=getRandomLinearForms(S1, {0,1,0,0, 0,0}, Homogeneous => true)
    else if (opts.Replacement == Binomial) then x=getRandomLinearForms(S1, {0,0,0,1, 0,0}, Homogeneous => true)
    else if (opts.Replacement == Trinomial) then x=getRandomLinearForms(S1, {0,0,0,0, 1,0}, Homogeneous => true)
    else if (opts.Replacement == Full) then x=getRandomLinearForms(S1, {0,0,0,0, 0,1}, Homogeneous => true)
    else x=getRandomLinearForms(S1, {0,0,0,1, 0,0}, Homogeneous => true);
    saturate(I1,ideal x)
)


--The following gets a list of random forms in a ring.  You specify how many.  
--if Verify is true, it will check to for linear independence of the monomial, binomial and randForms 
getRandomLinearForms = method(Options => {Verify => false, Homogeneous => false, Verbose=>false});
getRandomLinearForms(Ring, List) := opts -> (R1, L1) ->(
    if (opts.Verbose) or (debugLevel > 0) then print concatenate("getRandomLinearForms: starting, options:", toString(L1));
    constForms := L1#0;
    monomialForms := L1#1;
    trueMonomialForms := L1#2; --forced to be monomial whether or not Homogeneous is true
    binomialForms := L1#3; 
    trinomialForms := L1#4;
    randForms := L1#5;
    formList := {}; 
    genList := gens R1;
    d := #genList;
    --tempList is used if Verify => true, it tries to maximize linear independence of monomial and binomial forms,
    --this is important if you are trying to verify some ring map is actually surjective 
    if (d <= 0) then (
        
    );
    tempList := random genList;
    if (opts.Verify) then (
        if (#tempList < monomialForms + trueMonomialForms + binomialForms) then (tempList = tempList | apply(monomialForms + trueMonomialForms + binomialForms - #tempList, i->(genList)#(random d)));
    );
    if (opts.Homogeneous) then (
        if (opts.Verbose) or (debugLevel > 0) then print "getRandomLinearForms: generating homogeneous forms.";
        --monomialForms x,y,z
        if (opts.Verify) then (formList = formList | apply(monomialForms, i -> (tempList)#i);)
        else (formList = formList | apply(monomialForms, i -> (genList)#(random(d))););
        --true monomialForms, which is the same as monomial forms in the homogeneous case
        if (opts.Verify) then (formList = formList | apply(trueMonomialForms, i -> (tempList)#(i+monomialForms));)
        else (formList = formList | apply(trueMonomialForms, i -> (genList)#(random(d))););
        --binomial forms, x+by
        if (opts.Verify) then (formList = formList | apply(binomialForms, i -> (tempList)#(i+monomialForms+trueMonomialForms) + (random(0, R1))*(genList)#(random(d)));) 
        else (formList = formList | apply(binomialForms, i -> (genList)#(random(d)) + (random(0, R1))*(genList)#(random(d))););
        --trinomial forms, x+by+cz
        if (opts.Verify) then (formList = formList | apply(trinomialForms, i -> (tempList)#(i+monomialForms+trueMonomialForms) + (random(0, R1))*(genList)#(random(d))  + (random(0, R1))*(genList)#(random(d))  );) 
        else (formList = formList | apply(trinomialForms, i -> (genList)#(random(d)) + (random(0, R1))*(genList)#(random(d)) + (random(0, R1))*(genList)#(random(d))  ););
        --random forms
        formList = formList | apply(randForms, i-> random(1, R1));
    )
    else(
        if (opts.Verbose) or (debugLevel > 0) then print "getRandomLinearForms: generating non-homogeneous forms.";
        --monomial forms, x+a
        if (opts.Verify) then (formList = formList | apply(monomialForms, i -> random(0, R1) + (tempList)#i);)
        else (formList = formList | apply(monomialForms, i -> random(0, R1) + (genList)#(random(d))););
        --true monomial forms, x, y, z
        if (opts.Verify) then (formList = formList | apply(trueMonomialForms, i -> (tempList)#(i+monomialForms));)
        else (formList = formList | apply(trueMonomialForms, i -> (genList)#(random(d))););
        --binomial forms, x+by+c        
        if (opts.Verify) then (formList = formList | apply(binomialForms, i -> random(0, R1) + (tempList)#(i+monomialForms+trueMonomialForms) + (random(0, R1))*(genList)#(random(d)));) 
        else (formList = formList | apply(binomialForms, i -> random(0, R1) + (genList)#(random(d)) + (random(0, R1))*(genList)#(random(d))););
        --trinomial forms x+by+cz + d
        if (opts.Verify) then (formList = formList | apply(trinomialForms, i -> random(0, R1) + (tempList)#(i+monomialForms+trueMonomialForms) + (random(0, R1))*(genList)#(random(d))  + (random(0, R1))*(genList)#(random(d)));) 
        else (formList = formList | apply(trinomialForms, i -> random(0, R1) + (genList)#(random(d)) + (random(0, R1))*(genList)#(random(d)) + (random(0, R1))*(genList)#(random(d))));
        --random forms
        formList = formList | apply(randForms, i->random(0, R1) + random(1, R1));
    );
    if (opts.Verify) and (#formList > 0) then ( --if we are checking our work
        J1 := jacobian ideal formList;
        val := min(d, #formList);
        if (rank J1 < val) then ( 
            if (opts.Verbose) or (debugLevel > 0) then print "getRandomLinearForms: forms were not random enough, trying again recusrively.";            
            return getRandomLinearForms(R1, L1, opts);
        );
    );
    formList = formList | apply(constForms, i -> random(0, R1));

    return random formList;
);

randomPointViaLinearIntersection = method(Options => optRandomPoints);

randomPointViaLinearIntersection(ZZ, Ideal) := opts -> (n1, I1) -> (
    returnPointsList := {};
    R1 := ring I1;
    dR1 := dim R1;
    c1 := opts.Codimension;
    local d1;
    if (c1 === null) then (c1 = dR1 - (opts.DimensionFunction)(I1)); --don't compute it if we already know it.
    if (c1 == 0) then (
        if (opts.Verbose or debugLevel > 0) then print "randomPointViaLinearIntersection: 0 ideal was passed, switching to brute force.";
        return searchPoints(n1, ring I1, first entries gens I1, opts++{PointCheckAttempts => 10*n1});
    );
    d1 = dR1-c1;
    i := 0;
    j := 0;
    local finalPoint;
    local ptList; local newPtList;
    local phi;
    local psi;
    local myDeg;
    local myDim;
    local m2;
    local targetSpace;
    local phiMatrix;
    local J1;
    local myPowerList;
    local kk; --the extended field, if we extended
    local varList;
    kk = coefficientRing(R1);
    if (d1 == -infinity) then (if (opts.Verbose or debugLevel > 0) then print "randomPointViaLinearIntersection: no points, the ideal is the unit ideal."; return returnPointsList;) else (varList = drop(gens R1, d1););  --if the unit ideal is passed, then there are no points
    toReplace := max(0, min(opts.MaxCoordinatesToReplace, c1));
    toTrivialize := min(d1, opts.MaxCoordinatesToTrivialize);
    while(i < opts.IntersectionAttempts) and (#returnPointsList < n1) do (
        targetSpace = kk[varList];        
        if (opts.Replacement == Binomial) then (
            phiMatrix = getRandomLinearForms(targetSpace, {toTrivialize, 0, c1-toReplace + (d1 - toTrivialize), toReplace, 0,  0}, Homogeneous => false, Verify=>true);
        )
        else if (opts.Replacement == Full) then (
            phiMatrix = getRandomLinearForms(targetSpace, {toTrivialize, 0, c1-toReplace + (d1 - toTrivialize), 0, 0, toReplace}, Homogeneous => false, Verify=>true);
        );
        if (opts.Verbose) or (debugLevel > 0) then print concatenate("randomPointViaLinearIntersection: doing loop with ", toString( phiMatrix));
        if (debugLevel > 0 or opts.Verbose == true) then print concatenate("randomPointViaLinearIntersection:  Doing a loop with:", toString(phiMatrix));
        phi = map(targetSpace, R1, phiMatrix);
        J1 = phi(I1);        
        if ((opts.DimensionFunction) J1 == 0) then (
        --if ((dimViaBezout(J1, DimensionIntersectionAttempts=>1, MinimumFieldSize=>5)) == 0) then (
        --if (dimViaBezoutIsZero(J1)) then (
            if (c1 == 1) then ( --if we are intersecting with a line, we can go slightly faster by using factor instead of decompose
                ptList = apply(toList factor(gcd(first entries gens J1)), t->ideal(t#0));
            )
            else (
                ptList = random decompose(J1);
            );
            j = 0;
            while (j < #ptList) and (#returnPointsList < n1) do (
                myDeg = degree(ptList#j);                
                if (myDeg == 1) then (
                    finalPoint = first entries evalAtPoint(R1, matrix{phiMatrix}, idealToPoint(ptList#j));
                    --finalPoint = apply(idealToPoint(ptList#j), s -> sub(s, R1));
                    if (verifyPoint(finalPoint, I1, opts)) then returnPointsList = append(returnPointsList, finalPoint);
                )
                else if (opts.ExtendField == true) then (
                    if (debugLevel > 0) or (opts.Verbose) then print "randomPointViaLinearIntersection:  extending the field.";
                    psi = (extendFieldByDegree(myDeg, targetSpace))#1;
                    newR1 := target psi;
                    m2 = psi(ptList#j);
                    newPtList = random decompose(m2); --make sure we are picking points randomly from this decomposition
                    --since these points are going to be conjugate, we only pick 1.  
                    if (#newPtList > 0) then ( 
                        finalPoint = first entries evalAtPoint(newR1, matrix{phiMatrix}, idealToPoint(newPtList#0));
                        --finalPoint =  apply(idealToPoint(newPtList#0), s -> sub(s, target phi));
                        if (verifyPoint(finalPoint, I1, opts)) then returnPointsList = append(returnPointsList, finalPoint);
                    ); 
                );
                j = j+1;
            );
        );
        if (debugLevel > 0) or (opts.Verbose) then(
            if (#returnPointsList < n1) then 
                print ("randomPointViaLinearIntersection:  found " | toString(#returnPointsList) | " points so far, trying a new linear space.")
            else print ("randomPointViaLinearIntersection:  found " | toString(#returnPointsList) | " points so far, stopping.");
        );
        i = i+1;
    );
    return returnPointsList;
);



randomPointViaGenericProjection = method(Options => optRandomPoints);
randomPointViaGenericProjection(ZZ, Ideal) := opts -> (n1, I1) -> (
    pointsList := {}; --a list of points to output
    flag := true;
    local phi;
    local psi;
    local I0;
    local J0;
    local pt;
    local pts; --a list of points produced by 
    local ptList;
    local j;
    local k;
    local finalPoint;
    local newPtList;
    local phi;
    local myDeg;
    local myDim;
    local m2; 
    i := 0;
    c1 := opts.Codimension;
    while (flag) and (i < opts.ProjectionAttempts) and (#pointsList < n1) do (
        if (opts.Codimension === null) then (
            c1 = dim ring I1 - (opts.DimensionFunction)(I1);
            if (c1 == infinity) then (
                if (opts.Verbose or debugLevel > 0) then print "randomPointViaGenericProjection: no points, the ideal is the unit ideal."; 
                return pointsList;
            )
            else if (c1 == 0) then (
                if (opts.Verbose or debugLevel > 0) then print "randomPointViaGenericProjection: 0 ideal was passed, switching to brute force.";
                return searchPoints(n1, ring I1, first entries gens I1, opts++{PointCheckAttempts => 10*n1});
            )
            else if (c1 == 1) then ( --don't project, if we are already a hypersurface
                phi = map(ring I1, ring I1);
                I0 = I1;
            )
            else(
                (phi, I0) = projectionToHypersurface(I1, Homogeneous=>opts.Homogeneous, Replacement => opts.Replacement, MaxCoordinatesToReplace => opts.MaxCoordinatesToReplace, Codimension => c1, Verbose=>opts.Verbose);
            );
        )
        else if (opts.Codimension == 1) then (
            phi = map(ring I1, ring I1);
            I0 = I1;
        )
        else if (opts.Codimension == infinity) then (
            if (opts.Verbose or debugLevel > 0) then print "randomPointViaGenericProjection: no points, the ideal is the unit ideal."; 
            return pointsList;
        )
        else if (c1 == 0) then (
            if (opts.Verbose or debugLevel > 0) then print "randomPointViaGenericProjection: 0 ideal was passed, switching to brute force.";
            return searchPoints(n1, ring I1, first entries gens I1, opts++{PointCheckAttempts => 10*n1});
        )
        else(
            (phi, I0) = projectionToHypersurface(I1, Homogeneous=>opts.Homogeneous, Replacement => opts.Replacement, MaxCoordinatesToReplace => opts.MaxCoordinatesToReplace, Codimension => opts.Codimension, Verbose=>opts.Verbose);
        );
        if ((dim ring I0 - (opts.DimensionFunction)(I0)) == 1) then (
            if (debugLevel > 0) or opts.Verbose then print "randomPointViaGenericProjection:  found a good generic projection, now finding a point on it.";
            if (opts.Strategy == GenericProjection) then (
                pts = randomPoints(n1-#pointsList, I0, switchStrategy(opts, BruteForce)))
            else if (opts.Strategy == HybridProjectionIntersection) then (
                pts = random randomPoints(n1-#pointsList, I0, switchStrategy(opts, LinearIntersection))
            ); --find a point on the generic projection (differently, depending on strategy)
            if (#pts > 0) then (
                k = 0;
                while (k < #pts) and (#pointsList < n1) do ( --we produced some other points, now lift them
                    pt = pts#k;
                    J0 = I1 + sub(ideal apply(dim source phi, i -> (first entries matrix phi)#i - sub(pt#i, target phi)), target phi); --lift the point to the original locus
                    if dim(J0) == 0 then( --hopefully the preimage is made of points
                        ptList = random decompose(J0);
                        j = 0;
                        while (j < #ptList) and (#pointsList < n1) do ( --points we produced
                            myDeg = degree (ptList#j);
                            --print myDeg;
                            if (myDeg == 1) then (
                                finalPoint = apply(idealToPoint(ptList#j), s -> sub(s, coefficientRing ring I1));
                                if (verifyPoint(finalPoint, I1, opts)) then pointsList = append(pointsList, finalPoint);
                            )                        
                            else if (opts.ExtendField == true) then (
                                if (debugLevel > 0) or (opts.Verbose) then print "randomPointViaGenericProjection:  extending the field.";
                                psi = (extendFieldByDegree(myDeg, ring ptList#j))#1;
                                m2 = psi(ptList#j);
                                newPtList = random decompose(m2);
                                if (#newPtList > 0) then ( 
                                    finalPoint =  apply(idealToPoint(newPtList#0), s -> sub(s, target psi));
                                    if (verifyPoint(finalPoint, I1, opts)) then pointsList = append(pointsList, finalPoint);
                                ); 
                            );
                            j = j+1;
                        )
                    )
                    else(
                        if (debugLevel > 0) or opts.Verbose then print "randomPointViaGenericProjection:  Lift of point is not a point (our projection was not sufficiently generic).";
                    );
                    k = k+1;
                );
            );
        );
        if (debugLevel > 0) or (opts.Verbose) then print ("randomPointViaGenericProjection: found " | toString(#pointsList) | " points so far.  We may do another loop.");
        i = i+1;
    );
    return pointsList;
);

-*
checkRandomPoint =(I1)->(
    genList:= first entries gens I1;
	K:=coefficientRing ring I1;
    point:=randomPoints(ring I1);
	eval:= map(K,ring I1,point);
	j:=0;
	while(j< #genList) do (
        tempEval:=eval(genList_j);
        if not (tempEval==0) then return {};
        j=j+1
    );
    if (tempEval ==0) then return point else return {};
)*-

randomPointViaDefaultStrategy = method(Options => optRandomPoints);
randomPointViaDefaultStrategy(ZZ, Ideal) := List => opts -> (n1, I1) -> (
    local fieldSize;
    pointsList := {}; --a list of points to output

    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 0): trying a quick brute force with 10 attempts.";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
            opts++{ Strategy=>BruteForce, PointCheckAttempts => 10 }
        );
    if (#pointsList >= n1) then return pointsList;
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 0): brute force failed, now computing the dimension (if not provided)";    
    c1 := opts.Codimension;
    if (c1 === null) then (c1 = dim ring I1 - (opts.DimensionFunction)(I1)); --don't compute it if we already know it.
    if (c1 == infinity) then (
        if (opts.Verbose or debugLevel > 0) then print "randomPointViaDefaultStrategy: the ideal has no points (it is the unit ideal)";
        return pointsList;
    );

    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy: starting";
    --we can do a brute force attempt for hypersurfaces when the field is small
    if (c1 == 1) then (
        if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 0): trying BruteForce";
        kk := coefficientRing ring I1;
        if (instance(kk, GaloisField)) then (
            fieldSize = ((degree (ideal ambient kk)_0)#0);
        )
        else if (ambient kk === ZZ) then (
            fieldSize = char kk;
        )
        else(
            error "You must be working over ZZ/p or a GaloisField";
        );
        pointsList = pointsList | randomPointsBranching(n1, I1, opts++{Strategy=>BruteForce, PointCheckAttempts=>min(30*n1, 4*n1*fieldSize)});
    );
    




    --lets give a quick generic projection a shot (well, the hybrid version)
    if (opts.ProjectionAttempts > 0) then (
        if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 1): trying a quick projection, coordinates only";
        pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
            opts++{ Strategy=>HybridProjectionIntersection,
                    Codimension=>c1,
                    MaxCoordinatesToReplace => 0,
                    Replacement => Binomial,
                    MaxCoordinatesToTrivialize => infinity,
                    ProjectionAttempts => 2,
                    IntersectionAttempts => 2*n1,                    
                }
        );
    );
    if (#pointsList >= n1) then return pointsList;


    --next do a very fast intersection with coordinate linear spaces
    if (#pointsList >= n1) then return pointsList;
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 2): trying a quick linear intersection, coordinates only";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => 0,
                IntersectionAttempts => 2*n1,
                MaxCoordinatesToTrivialize => infinity
            }
    );

    if (#pointsList >= n1) then return pointsList;
    
    --next do a very fast intersection with nearly coordinate linear spaces
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 3): trying a quick linear intersection, coordinates and one binomial only";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => 1,
                Replacement => Binomial,
                MaxCoordinatesToTrivialize => infinity,
                IntersectionAttempts => 4*n1
            }
    );
    if (#pointsList >= n1) then return pointsList;
    
    --next do a fast intersection with slightly less trivial coordinate linear spaces
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 4): trying a quick linear intersection, coordinates and one random term only";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => 1,
                Replacement => Full,
                MaxCoordinatesToTrivialize => infinity,
                IntersectionAttempts => 4*n1
            }
    );
    if (#pointsList >= n1) then return pointsList;
    
    --lets give generic projection another shot
    if (opts.ProjectionAttempts > 0) then (
        if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 5): giving projection another shot, coordinates and one binomial only";
        pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
            opts++{ Strategy=>HybridProjectionIntersection,
                    Codimension=>c1,
                    MaxCoordinatesToReplace => 1,
                    Replacement => Binomial,
                    MaxCoordinatesToTrivialize => infinity,
                    ProjectionAttempts => 3,
                    IntersectionAttempts => 4*n1
                }
        );
    );
    if (#pointsList >= n1) then return pointsList;
    
    --now do a intersection with linear spaces involving fewer coordinates
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 6): trying a quick linear intersection, coordinates and two binomials only";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => 2,
                Replacement => Binomial,
                MaxCoordinatesToTrivialize => 4,
                IntersectionAttempts => 4*n1
            }
    );
    if (#pointsList >= n1) then return pointsList;
    
    --first do a slower intersection with linear spaces involving fewer coordinates
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 7): trying a quick linear intersection, coordinates and two linear terms only";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => 2,
                Replacement => Full,
                MaxCoordinatesToTrivialize => 2,
                IntersectionAttempts => 4*n1
            }
    );
    if (#pointsList >= n1) then return pointsList;
    
    --this one is probably quite slow
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 8): trying a linear intersection, binomials only";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => infinity,
                Replacement => Binomial,
                MaxCoordinatesToTrivialize => 1,
                IntersectionAttempts => 4*n1
            }
    );
    if (#pointsList >= n1) then return pointsList;

        --lets try another projection
    if (opts.ProjectionAttempts > 0) then (
        if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 9): giving projection another shot, coordinates and two binomials only";
        pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
            opts++{ Strategy=>HybridProjectionIntersection,
                    Codimension=>c1,
                    MaxCoordinatesToReplace => 2,
                    Replacement => Binomial,
                    MaxCoordinatesToTrivialize => 2,
                    ProjectionAttempts => 3*n1,
                    IntersectionAttempts => 4*n1
                }
        );
    );
    if (#pointsList >= n1) then return pointsList;
    
    --this one can be extremely slow
    if (opts.Verbose) or (debugLevel > 0) then print "randomPointViaDefaultStrategy(step 10): trying a linear intersection, full random";
    pointsList = pointsList | randomPointsBranching(n1 - #pointsList, I1, 
        opts++{ Strategy=>LinearIntersection,
                Codimension=>c1,
                MaxCoordinatesToReplace => infinity,
                Replacement => Full,
                MaxCoordinatesToTrivialize => 1,
                IntersectionAttempts => 4*n1
            }
    );
    return pointsList;
);


randomPointViaMultiplicationTable=method(Options => optRandomPoints);


randomPointViaMultiplicationTable(ZZ,Ideal) := opts-> (n1,I) -> (
    local d;
    if not (opts.Codimension === null) then (d = (dim ring I) - opts.Codimension;)
    else (d = (opts.DimensionFunction) I;);
    --d:= dimViaBezout I;
    ptlist:={};
    while (#ptlist<n1) do (
           ptlist = append(ptlist, randomPointViaMultiplicationTable(I,d,opts));
	   );
    return ptlist
)

randomPointViaMultiplicationTable(Ideal,ZZ) := opts-> (I,d) -> (
    -- Input: I, a homogeneous ideal, d its dimension
    --Output: a K-rational point on V(I) where K is  the finite ground field.
    if not isHomogeneous I then error "randomPointViaMultiplicationTable: expected a homogeneous ideal";
    switchStrategy(opts,MultiplicationTable);
    -- we cut down with a linear space to a zero-dimensional projective scheme
    -- and compute how the last two variables act on the quotient ring truncated  
    -- at the regularity. 
    -- In case of an absolutely irreducible I over K, we will find with 
    -- high probability a point, 
    -- since the determinant will has a linear factor in at least 50% of the cases
    S:= ring I;
    attemps:=1;
    while (
        L:=ideal random(S^1,S^{d-1:-1});
	--elapsedTime J=saturate(I+L);
	    J:=I+L;
    	Js:=saturateInGenericCoordinates J;
        --Js := saturate(J, ideal first entries vars S);
	    r:=degree ideal last (entries gens gb Js)_0;
        b1 :=basis(r+1,S^1/Js); --if not homogeneous
	    b2 :=basis(r+2,S^1/Js);
	    j:=#gens S-d;
	    xx:=(support (vars S%L))_{j-1,j}; --last two equations (why last?)
	    m0:=contract(transpose matrix entries b2,matrix entries((xx_0*b1)%Js));  --contract 
	    m1:=contract(transpose matrix entries b2,matrix entries((xx_1*b1)%Js));
        M:=map(S^(rank target m0),S^{rank source m0:-1},xx_0*m1-xx_1*m0);
 	    DetM:=(M^{0}*syz M^{1..rank source M-1})_(0,0); --fake determinant computation  
         --look at examples of this matrix and see what happens, is this syz trick the way to compute
         --this will be slow if the degree is large since the size of this matrix is the degree
	     --computing DetM is the bottleneck
	    h:=ideal first first factor DetM;
	    --print degree h <<endl;
	    degree h>1 and attemps<opts.IntersectionAttempts) 
    do (attemps=attemps+1); --end of while
    if degree h >1 then return {};
    pt:=radical saturateInGenericCoordinates(h+Js); --lift to a higher dimensional space
    flatten (entries syz transpose jacobian pt)
)

getNextValidFieldSize = method();
getNextValidFieldSize(ZZ, ZZ, ZZ) := (pp, d, targetSize) -> (
    i := 1;
    while (pp^(i*d) < targetSize) do (
        i = i+1;
    );
    i
);



--better canceling provided by Dan Grayson
cancel = task -> (
     << "cancelling task " << task << endl;
     cancelTask task; 
     while true do (
	  if isCanceled task then (<< "cancelled task terminated " << task << endl; break);
	  if isReady task then (taskResult task ; << "cancelled task finished " << task << endl; break);
	  nanosleep(10000000);
	  );
     << "cancelled task " << task << endl;
)

dimViaBezout(Ideal) := opts-> I1 -> (
    S1 := ring I1;
    m := getFieldSize coefficientRing S1;
    local attempts;
    local tr;
    local tempResult;
    local homog;
    if (opts.Homogeneous === null) then (homog = isHomogeneous I1) else (homog = opts.Homogeneous);
    pp := char ring I1;
    d := floor(log_pp(m) + 0.5);
    i := getNextValidFieldSize(pp, d, opts.MinimumFieldSize);
    if (opts.DimensionIntersectionAttempts === null) then (attempts = ceiling(log_10(1 + 5000/(pp^(i*d))))) else (attempts = opts.DimensionIntersectionAttempts;);
    if opts.Verbose then print ("dimViaBezout: Checking each dimension " | toString(attempts) | " times.");
    if (m >= opts.MinimumFieldSize) then (
        --The following is code for multithreading, if that is fixed.
        -*
        backtrace=false;
        t1 := createTask(myI -> (backtrace=false; return dimViaBezoutNonhomogeneous myI), (I1, Verbose=>false, DimensionIntersectionAttempts=>attempts));
        t2 := createTask(myI -> (backtrace=false; return dim myI), (I1));
        schedule t1;
        schedule t2;
        r1 := isReady(t1);
        r2 := isReady(t2);
        if opts.Verbose then print ("dimViaBezout:  starting threads, one classical dim, one probabilistic dim ");
        while (r1==false and r2==false) do ( nanosleep(100000); r1 = isReady(t1); r2 = isReady(t2););
        if opts.Verbose then print ("dimViaBezout:  found an answer" );
        if (r2) then (
            tr = taskResult(t2);
            if opts.Verbose then print ("dimViaBezout:  classical dim finished first: " | toString(tr) );            
            cancel t1;                       
            return tr;
        )
        else if (r1) then (
            tr = taskResult(t1);
            if opts.Verbose then print ("dimViaBezout:  probabilistic dim finished first: " | toString(tr));
            cancel t2;
            return tr;            
        );
        if opts.Verbose then print "dimViaBezout: Something went wrong with multithrading.";              
        return null;
        *-
        if (homog) then return dimViaBezoutHomogeneous(I1, DimensionIntersectionAttempts=>attempts) else 
        return dimViaBezoutNonhomogeneous(I1, Verbose=>opts.Verbose, DimensionIntersectionAttempts=>attempts);
    );
    if opts.Verbose then print "dimViaBezout: The field is too small, extending it.";
 
    
    if opts.Verbose then print ("dimViaBezout: New field size is " | toString(pp) | "^" | toString(i*d) | " = " | toString(pp^(i*d)) );
    (S2, phi1) := fieldBaseChange(S1, GF(pp, i*d));
    I2 := phi1(I1);    
    if (homog) then return dimViaBezoutHomogeneous(I2, DimensionIntersectionAttempts=>attempts) else 
    return dimViaBezoutNonhomogeneous(I2, Verbose=>opts.Verbose, DimensionIntersectionAttempts=>attempts);
)


rationalPointsNew = method(Options => optRandomPoints);
rationalPointsNew(ZZ, Ideal) := opts -> (n1, I1) -> (
    --this code is for the non-homogeneous case
    --the idea in this code is simple.  Extend the field.  Intersect with binomials.  
    --Then find the point, either by decompose or with a multiplication table
    local J2;
    local I3;
    local myDeg;
    local newS2;
    local psi;
    local j;
    local l; --a linear space
    local m2;  --a point, in an extended field
    local finalPoint; --the point to be returned    
    local J2;
    local ptList; --list of points, before extending the field.
    local sortedPtList; --list of points, before extending the field.
    local newPtList; --list of points after extending the field
    local checks;
    returnPointsList := {};
    if (opts.PointCheckAttempts > 0) then checks = opts.PointCheckAttempts else checks = 3*n1+3;    

    S1 := ring I1;
    m := getFieldSize coefficientRing S1;
    pp := char ring I1;
    S2 := S1;
    I2 := I1;    
    
    i := dim S1;
    k:= 0;
    --L2 := apply(checks, t-> getRandomLinearForms(S2, {0,max(0, i-t),0,min(t, i), 0,0}, Homogeneous=>false)); --a list of linear forms
    L2 := apply(checks, t-> getRandomLinearForms(S2, {0,i,0,0,0,0}, Homogeneous=>false));
    while (i >= 0) do (
        if opts.Verbose then print("rationalPointsNew: Trying intersection with a binomial linear space of dimension " | toString(dim S2 - i));        
        J2 = apply(L2, l -> ideal(l) + I2);
        k = 0;
        while (k < checks) and (#returnPointsList < n1) do (
            if opts.Verbose then print("rationalPointsNew: trying linear intersection #" | toString(k));
            --print (J2#k == ideal(1_S2));
            --print dim(J2#k);
            if (J2#k != ideal 1_S2) and (#returnPointsList < n1) then (--we found a point                
                --i = -1; --stop the exterior loop, we found the dimension
                if opts.Verbose then print("rationalPointsNew: We found at least one point");
                --we should have bifurcating code here, so instead of running this, call a function, or call the multiplication table
                ptList = random decompose trim  (J2#k);
                if opts.Verbose then print("rationalPointsNew: We found " | toString(#ptList) | " points.");
                j=0;
                sortedPtList = sort apply(#ptList, t -> {dim (ptList#t), degree (ptList#t), t});
                if opts.Verbose then print sortedPtList;
                while (j < #ptList) and (#returnPointsList < n1) and (sortedPtList#j#0 == 0) do (
                    myDeg = sortedPtList#j#1;                
                    if opts.Verbose then print("rationalPointsNew: Looking at a point of degree " | toString(myDeg));
                    if (myDeg == 1) then (
                        finalPoint = idealToPoint(ptList#(sortedPtList#j#2));                    
                        if (verifyPoint(finalPoint, I2, opts)) then returnPointsList = append(returnPointsList, finalPoint);
                    )
                    else (
                        if (debugLevel > 0) or (opts.Verbose) then print "rationalPointsNew: Found a non-rational point.";
                    );
                    j = j+1;
                );    
                --now we need to remove this item from the list of things to check       
                L2 = drop(L2, {k,k});    
                checks = checks - 1; --we have fewer things to check against now that this one is used up     
            );
            if (#returnPointsList >= n1) then return returnPointsList;
            k = k+1;
        );
        L2 = apply(checks, t->drop(L2#t, 1)); --drop something for next run
        i = i-1;        
    );
    return returnPointsList;
)

verifyDimZero = method();--verify if an ideal has dimension zero
verifyDimZero(Ideal) := (I1) -> (
    local S2;
    local phi1;
    local I2;
    S1 := ring I1;
    m := getFieldSize coefficientRing S1;    
    pp := char S1;
    curD := floor(log_pp(m) + 0.5);    
    if (m < 100000) then (
        d := ceiling(log_pp(max(m, 100000)));
        d = ceiling(d/curD)*d;
        (S2, phi1) = fieldBaseChange(S1, GF(pp, d));
        I2 = phi1(I1);  
    )
    else (
        I2 = I1;
        S2 = S1;
    );
    h := getRandomLinearForms(S2, {0,1,0,0,0,0}, Homogeneous => false);
    return (I2 + ideal(h) == ideal(1_S2));
);

geometricPointsNew = method(Options => optRandomPoints);
geometricPointsNew(ZZ, Ideal) := opts -> (n1, I1) -> (
    --this code is for the non-homogeneous case
    --the idea in this code is simple.  Extend the field.  Intersect with binomials.  
    --Then find the point, either by decompose or with a multiplication table
    local J2;
    local I3;
    local myDeg;
    local newS2;
    local psi;
    local j;
    local l; --a linear space
    local m2;  --a point, in an extended field
    local finalPoint; --the point to be returned    
    local J2;
    local ptList; --list of points, before extending the field.
    local sortedPtList; --list of points, before extending the field.
    local newPtList; --list of points after extending the field
    local checks;
    returnPointsList := {};
    if (opts.PointCheckAttempts > 0) then checks = opts.PointCheckAttempts else checks = 3*n1+3; 

    S1 := ring I1;
    m := getFieldSize coefficientRing S1;
    pp := char ring I1;
    d := ceiling(log_pp(max(m, 100)) + 0.5); --this should force a bigger field extension
    curD := floor(log_pp(m) + 0.5);--current degree
    d = ceiling(d/curD)*d;
    if opts.Verbose then print "geometricPointsNew: Extending the field";
    if opts.Verbose then print ("geometricPointsNew: New field size is " | toString(pp) | "^" | toString(d) | " = " | toString(pp^(d)) );
    (S2, phi1) := fieldBaseChange(S1, GF(pp, d));
    I2 := phi1(I1);    
    
    i := dim S1;
    k:= 0;
    L2 := apply(checks, t-> getRandomLinearForms(S2, {0,i,0,0,0,0}, Homogeneous=>false));
    --L2 := apply(checks, t-> getRandomLinearForms(S2, {0,max(0, i-t),0,min(t, i), 0,0}, Homogeneous=>false)); --a list of linear forms
    while (i >= 0) do (
        if opts.Verbose then print("geometricPointsNew: Trying intersection with a binomial linear space of dimension " | toString(dim S2 - i));        
        J2 = apply(L2, l -> ideal(l) + I2);
        k = checks - 1;
        while (k >= 0) and (#returnPointsList < n1) do (
            if opts.Verbose then print("geometricPointsNew: trying linear intersection #" | toString(k));
            if (J2#k != ideal 1_S2) and (#returnPointsList < n1) then (--we found a point                
                if opts.Verbose then print("geometricPointsNew: We found something");
                if (dim (J2#k) == 0) then (
                    --i = -1; --stop the exterior loop, we found the dimension
                    if opts.Verbose then print("geometricPointsNew: We found at least one point");
                    --we should have bifurcating code here, so instead of running this, call a function, or call the multiplication table
                    ptList = random decompose(J2#k);
                    if opts.Verbose then print("geometricPointsNew: We found " | toString(#ptList) | " points.");
                    j=0;
                    sortedPtList = sort apply(#ptList, t -> {dim (ptList#t), degree (ptList#t), t});
                    while (j < #ptList) and (#returnPointsList < n1) and (sortedPtList#j#0 == 0) do (
                        myDeg = sortedPtList#j#1;                
                        if opts.Verbose then print("geometricPointsNew: Looking at a point of degree " | toString(myDeg));
                        if (myDeg == 1) then (
                            finalPoint = idealToPoint(ptList#(sortedPtList#j#2));                    
                            if (verifyPoint(finalPoint, I2, opts)) then returnPointsList = append(returnPointsList, finalPoint);
                        )
                        else if (not (null === conwayPolynomial(pp, d*myDeg))) then (
                            if (debugLevel > 0) or (opts.Verbose) then print "geometricPointsNew:  extending the field.";
                            psi = (extendFieldByDegree(myDeg, S2))#1;
                            I3 = psi(I2);
                            newS2 = target psi;
                            m2 = psi(ptList#j);
                            newPtList = random decompose(m2); --make sure we are picking points randomly from this decomposition
                            --since these points are going to be conjugate, we only pick 1.                      
                            if (#newPtList > 0) then ( 
                                finalPoint = idealToPoint(newPtList#0);
                                --finalPoint =  apply(idealToPoint(newPtList#0), s -> sub(s, target phi));
                                if (verifyPoint(finalPoint, I3, opts)) then (returnPointsList = append(returnPointsList, finalPoint);)                        
                            ); 
                        )
                        else (
                            if (debugLevel > 0) or (opts.Verbose) then print "geometricPointsNew: Macaulay2 cannot handle a field extension this large, moving to the next point.";
                        );
                        j = j+1;                    
                    );   
                );
                --now we need to remove this item from the list of things to check    
                L2 = drop(L2, {k,k});    
                checks = checks - 1;     --we have fewer things to check against now that this one is used up
            );
            if (#returnPointsList >= n1) then return returnPointsList;
            k = k-1;
        );
        L2 = apply(checks, t->drop(L2#t, 1)); --drop something for next run
        i = i-1;        
    );
    return returnPointsList;
)

linearIntersectionNew = method(Options => optRandomPoints);
linearIntersectionNew(ZZ, Ideal) := opts -> (n1, I1) -> (
    --this code is for the non-homogeneous case
    --the idea in this code is simple.  Extend the field.  Intersect with binomials.  
    --Then find the point, either by decompose or with a multiplication table
    local J2;
    local I3;
    local myDeg;
    local S2;
    local I2;
    local phi1;
    local newS2;
    local psi;
    local j;
    local l; --a linear space
    local m2;  --a point, in an extended field
    local finalPoint; --the point to be returned    
    local J2;
    local ptList; --list of points, before extending the field.
    local sortedPtList; --list of points, before extending the field.
    local newPtList; --list of points after extending the field
    local checks;
    local newPts; --new points as found by the multiplication table helper function
    local d;
    local L2;
    local workingIdeal;
    returnPointsList := {};
    if (opts.PointCheckAttempts >= 1 ) then checks = opts.PointCheckAttempts else if (opts.ExtendField) then  checks = 3*n1+3 else checks = 3*n1+3;  

    S1 := ring I1;
    m := getFieldSize coefficientRing S1;
    pp := char ring I1;
    if (opts.ExtendField) then ( 
        d = ceiling(log_pp(max(m, 100)) + 0.5); --this should force a bigger field extension
        curD := floor(log_pp(m) + 0.5);--current degree
        if opts.Verbose then print "linearIntersectionNew: Extending the field";
        if opts.Verbose then print ("linearIntersectionNew: New field size is " | toString(pp) | "^" | toString(d) | " = " | toString(pp^(d)) );
        d = ceiling(d/curD)*d; --make sure our extension degree is a multiple of the old degree
        (S2, phi1) = fieldBaseChange(S1, GF(pp, d));
        I2 = phi1(I1);    
    )
    else(
        d = floor(log_pp(m) + 0.5); --the current degree, for later storage
        S2 = S1;
        I2 = I1;
    );
    i := dim S1;
    k:= 0;

    homogFlag := (opts.DecompositionStrategy === MultiplicationTable) and isHomogeneous(I1); --this flag is set to true if we are homogeneous, and the DecompositionStrategy is multiplication table
    
    --depending on what was passed, we choose a list of 
    if (class opts.Replacement === List) then (
        if (not (sum opts.Replacement == i)) and (opts.Verbose) then print "linearIntersectionNew: Warning, you passed a replacement scheme but the terms did not add up to the ambient dimension."; 
        L2 = apply(checks, t-> getRandomLinearForms(S2, opts.Replacement, Homogeneous=>homogFlag, Verify=>true)); --a list of linear forms
    )
    else if (opts.Replacement === Monomial) then (
        L2 = apply(checks, t -> getRandomLinearForms(S2, {0, i, 0, 0, 0, 0}, Homogeneous=>homogFlag, Verify=>true));
    )
    else if (opts.Replacement === Binomial) then (
        L2 = apply(checks, t -> getRandomLinearForms(S2, {0, 0, 0, i, 0, 0},Homogeneous=>homogFlag, Verify=>true));
    )
    else if (opts.Replacement === Trinomial) then (
        L2 = apply(checks, t -> getRandomLinearForms(S2, {0, 0, 0, 0, i, 0},Homogeneous=>homogFlag, Verify=>true));
    )
    else if (opts.Replacement === Full) then (
        L2 = apply(checks, t -> getRandomLinearForms(S2, {0, 0, 0, 0, 0, i}, Homogeneous=>homogFlag, Verify=>true));
    )
    else (
        L2 = apply(checks, t-> getRandomLinearForms(S2, {0,max(0, i-t),0,min(t, i), 0,0}, Homogeneous=>homogFlag, Verify=>true)); --a list of linear forms, some monomial, some binomial
    ); --now we have picked the linear forms, we begin our loop
    while (i >= 0) do (
        if opts.Verbose then print("linearIntersectionNew: Trying intersection with a linear space of dimension " | toString(dim S2 - i));        
        J2 = apply(L2, l -> ideal(l) + I2);
        k = checks-1; --this should change to start at checks-1 and loop backwards
        while (k >= 0) and (#returnPointsList < n1) do (
            if opts.Verbose then print("linearIntersectionNew: trying linear intersection #" | toString(k));
            workingIdeal = J2#k;
            --if (homogFlag) then workingIdeal = saturate workingIdeal; --make this saturation faster
            if (homogFlag) then workingIdeal = saturateInGenericCoordinates workingIdeal; --make this saturation faster
            if (workingIdeal != ideal 1_S2) and (#returnPointsList < n1) then (--we found a point                
                --i = -1; --stop the exterior loop, we found the dimension
                if opts.Verbose then print("linearIntersectionNew: We found something.");
                if ((not homogFlag) and (dim workingIdeal == 0)) then (--if we are using decompose
                    if opts.Verbose then print("linearIntersectionNew: We found at least one point");
                    --we should have bifurcating code here, so instead of running this, call a function, or call the multiplication table
                    
                    ptList = random decompose trim (workingIdeal);                        
                    if opts.Verbose then print("linearIntersectionNew: We found " | toString(#ptList) | " points.");
                    j=0;
                    sortedPtList = sort apply(#ptList, t -> {dim (ptList#t), degree (ptList#t), t});
                    while (j < #ptList) and (#returnPointsList < n1) and (sortedPtList#j#0 == 0) do (
                        myDeg = sortedPtList#j#1;                
                        if opts.Verbose then print("linearIntersectionNew: Looking at a point of degree " | toString(myDeg));
                        if (myDeg == 1) then (
                            finalPoint = idealToPoint(ptList#(sortedPtList#j#2));                    
                            if (verifyPoint(finalPoint, I2, opts)) then returnPointsList = append(returnPointsList, finalPoint);
                        )
                        else if (opts.ExtendField) and (not (null === conwayPolynomial(pp, d*myDeg)))  then (
                            if (debugLevel > 0) or (opts.Verbose) then print "linearIntersectionNew:  extending the field.";
                            psi = (extendFieldByDegree(myDeg, S2))#1;
                            I3 = psi(I2);
                            newS2 = target psi;
                            m2 = psi(ptList#j);
                            newPtList = random decompose(m2); --make sure we are picking points randomly from this decomposition
                            --since these points are going to be conjugate, we only pick 1.                      
                            if (#newPtList > 0) then ( 
                                finalPoint = idealToPoint(newPtList#0);
                                --finalPoint =  apply(idealToPoint(newPtList#0), s -> sub(s, target phi));
                                if (verifyPoint(finalPoint, I3, opts)) then (returnPointsList = append(returnPointsList, finalPoint);)                        
                            ); 
                        )
                        else if (opts.ExtendField) then (
                            if (debugLevel > 0) or (opts.Verbose) then print "linearIntersectionNew: Macaulay2 cannot handle a field extension this large, moving to the next point.";
                        );
                        j = j+1;
                    );                                                                
                )
                else if homogFlag and (dim workingIdeal == 1) then (--we should use MultiplicationTable to do the factoring
                    newPts = multiplicationTableInternal(n1 - #returnPointsList, I2, workingIdeal, sub(ideal(L2#k), S2), ExtendField => opts.ExtendField, Verbose=>opts.Verbose);
                    returnPointsList = returnPointsList | newPts;                                       
                );  
                L2 = drop(L2, {k,k});
                checks = checks-1; --we have fewer linear forms now      
                if (debugLevel > 0) or (opts.Verbose) then print "linearIntersectionNew: Removing linear space from the list, this one found something.";
            );
            if (#returnPointsList >= n1) then return returnPointsList;
            k = k-1;
        );
        L2 = apply(checks, t->drop(L2#t, 1)); --drop something for next run
        i = i-1;        
    );
    return returnPointsList;
)

multiplicationTableInternal = method(Options=>{ExtendField => false, Verbose=>false});
multiplicationTableInternal(ZZ, Ideal, Ideal, Ideal) := opts->(n1, I2, workingIdeal, linearSpace) -> (
    local newPt;
    returnPointsList := {};
    S2 := ring I2;
    if (degree workingIdeal == 1) then (--we don't have to do anything
        newPt = flatten (entries syz transpose jacobian workingIdeal);
        if (#newPt > dim S2) then error "multiplicationTableInternal: What is going on?";
        returnPointsList = append(returnPointsList, newPt);    
    )
    else ( --do the multiplication table thing
        r:=degree ideal last (entries gens gb workingIdeal)_0;
        b1 :=basis(r+1,S2^1/workingIdeal); 
        b2 :=basis(r+2,S2^1/workingIdeal);
        j := dim S2 - #(first entries gens linearSpace) - 1; --what size linear space did we intersect with
        if (opts.Verbose) then print ("multiplicationTableInternal: linear space codim is " | toString(j) | "," | toString(dim linearSpace) | " deg " | toString(degree workingIdeal));    
        xx:=(support (vars S2%(linearSpace)))_{j-1,j}; 
        m0:=contract(transpose matrix entries b2,matrix entries((xx_0*b1)%workingIdeal));  
        m1:=contract(transpose matrix entries b2,matrix entries((xx_1*b1)%workingIdeal));
        M:=map(S2^(rank target m0),S2^{rank source m0:-1},xx_0*m1-xx_1*m0);

        DetM:=(M^{0}*syz M^{1..rank source M-1})_(0,0);--fake determinant computation  
        if (not DetM == 0) then (
            h:= factor DetM;
            count := 0;
            while (count < #h) and (#returnPointsList < n1) do (
                myH := first (h#count);
                if (degree myH >= degree(0_S2)) and (degree myH == degree first first entries vars S2) then (--check to see if we have a degree 1 factor
                    --pt:=radical saturate((ideal myH)+workingIdeal); --lift to a higher dimensional space
                    pt:=radical saturateInGenericCoordinates((ideal myH)+workingIdeal); --lift to a higher dimensional space
                    if (degree pt == 1) then (
                        newPt = flatten (entries syz transpose jacobian pt);
                        verifyPoint(newPt, I2);
                        if (#newPt > dim S2) then error "multiplicationTableInternal: What is going on?";
                        returnPointsList = append(returnPointsList, newPt);                    
                    );
                );            
                count = count+1;
            );
        );
    );
    return returnPointsList; --return what we have done
);


randomPointViaMultiplicationTableNew=method(Options => optRandomPoints);
randomPointViaMultiplicationTableNew(ZZ, Ideal) := opts-> (n1, I1) -> (
    --this variant of the function finds geometric points
    -- Input: I, a homogeneous ideal, n1, the number of points to find
    --Output: a K-rational point on V(I) where K is  the finite ground field.    
    -- we cut down with a linear space to a zero-dimensional projective scheme
    -- and compute how the last two variables act on the quotient ring truncated  
    -- at the regularity.     
    local k;
    local J2;
    local Js;
    returnPointsList := {};

    S1:= ring I1;
    checks := 3*n1+3;
    m := getFieldSize coefficientRing S1;
    pp := char ring I1;
    d := ceiling(log_pp(max(m, 1000)) + 0.1); --this should force a field with > 1000 elts
    if opts.Verbose then print "randomPointViaMultiplicationTableNew: Extending the field";
    if opts.Verbose then print ("randomPointViaMultiplicationTableNew: New field size is " | toString(pp) | "^" | toString(d) | " = " | toString(pp^(d)) );
    (S2, phi1) := fieldBaseChange(S1, GF(pp, d));
    I2 := phi1(I1);    
    
    i := dim S1-1;
    L2 := apply(checks, t-> getRandomLinearForms(S2, {0,max(0, i-t),0,min(t, i),0,0}, Homogeneous=>true)); 
        --a list of all the linear forms to use    
    
    while (i >= 0) and (#returnPointsList < n1) do (
        if opts.Verbose then print("randomPointViaMultiplicationTableNew: Trying intersection with a binomial linear space of dimension " | toString(dim S2 - i));        
        J2 = apply(L2, l -> ideal(l) + I2); -- a list of intersections
        k = 0;
        while (k < checks) and (#returnPointsList < n1) do (
             if opts.Verbose then print("randomPointViaMultiplicationTableNew: trying linear intersection #" | toString(k));
            Js = saturate(J2#k);
            if (Js != ideal 1_S2) and (#returnPointsList < n1) then (
               
                -----THE FOLLOWING CODE MAY NEED TO BE MODIFIED FURTHER
                --Js:=saturateInGenericCoordinates(J2#k); --this should saturate pretty quickly                
                r:=degree ideal last (entries gens gb Js)_0;
                b1 :=basis(r+1,S2^1/Js); 
                b2 :=basis(r+2,S2^1/Js);
                j:=dim S1 - i-1; --the expected codimension of I2
                xx:=(support (vars S2%(ideal(L2#k))))_{j-1,j}; 
                m0:=contract(transpose matrix entries b2,matrix entries((xx_0*b1)%Js));  --contract 
                m1:=contract(transpose matrix entries b2,matrix entries((xx_1*b1)%Js));
                M:=map(S2^(rank target m0),S2^{rank source m0:-1},xx_0*m1-xx_1*m0);
                DetM:=(M^{0}*syz M^{1..rank source M-1})_(0,0); --fake determinant computation  
                --look at examples of this matrix and see what happens, is this syz trick the way to compute
                --this will be slow if the degree is large since the size of this matrix is the degree
                --computing DetM is the bottleneck
                --h:=ideal first first factor DetM;                
                if (not DetM == 0) then (
                    h:= factor DetM;
                    count := 0;
                    while (count < #h) and (#returnPointsList < n1) do (
                        myH := first (h#count);
                        if (degree myH >= degree(0_S2)) and (degree myH == degree first first entries vars S2) then (--check to see if we have a degree 1 factor
                            pt:=radical saturateInGenericCoordinates((ideal myH)+Js); --lift to a higher dimensional space
                            if (degree pt == 1) then (
                                returnPointsList = append(returnPointsList, flatten (entries syz transpose jacobian pt));
                                i = -1; --also, stop the big loop
                            );
                        );            
                        count = count+1;
                    );
                );
                --print degree h <<endl;
                    --degree h>1 and attemps<opts.IntersectionAttempts
                --) 
                --do (attemps=attemps+1); --end of while
                --if degree h >1 then return {};                
            );
            k = k+1;
        );
        
        --drop a form for next run
        L2 = apply(checks, t->drop(L2#t, 1));
        i = i-1;
    );
    return returnPointsList;
)



--dimViaBezout(ZZ, Ideal) := (n1,I1) -> (
    --if (isHomogeneous I1) then (
        --valList := sort apply(n1, i->dimViaBezoutHomogeneous(5, I1));
        --max valList
    --)
    --else(
        --dimViaBezoutNonhomogeneous(1, I1)
    --)
--)


dimViaBezoutNonhomogeneous=method(Options => {Verbose => false, DimensionIntersectionAttempts => 1, MinimumFieldSize => 100});

dimViaBezoutNonhomogeneous(Ideal) := opts -> (I1)->(
    S1 := ring I1;
    --if (getFieldSize(S1)<39) then return codim I1;
    i := dim S1-1;
    checks := opts.DimensionIntersectionAttempts;
    while (i >= 0) do (
        if opts.Verbose then print("dimViaBezoutNonhomogeneous: Trying intersection with a linear space of dimension " | toString(dim S1 - i));
        if (i == 0) then checks = 1;
        L1 := apply(checks, t->ideal getRandomLinearForms(S1, {0,0,0,0,0,i}));
        --print L1;
        --print trim(I1 + L1);
        myList := apply(L1, l -> (l + I1 != ideal 1_S1));
        if all(myList, b->b) then return i;
        --if (L1 + I1 != ideal 1_S1) then return i;
        --print dim(L1 + I1);
        i = i-1;
        --print i;
    );        
    return -1;
)



getFieldSize = method();

needsPackage "PushForward";

getFieldSize(Ring):= (k1) -> (    
    if instance(k1, GaloisField) then return (char k1)^((degree (ideal ambient k1)_0)#0);
    if instance(k1, QuotientRing) then (
        if ambient(k1) === ZZ then return char k1;
        pp := char k1;
        l1 := ZZ/pp[];
        inc := map(k1, l1, {});
        return pp^(rank ((pushFwd(inc))#0));
    );
    infinity
)

dimViaBezoutHomogeneous=method(Options => {DimensionIntersectionAttempts => 1});

dimViaBezoutHomogeneous(Ideal) := opts-> (I1) -> (
    S1:=ring I1;
--    randomMon := ideal((gens S1)#(random(#gens S1)));
    --if (I1 == ideal 1_S1) then return -1;
    if (I1 == ideal 0_S1) then return dim S1;
    lowerBound := max(dim S1-rank source gens I1,0);
    upperBound := dim S1;
    mid:= null; 
    i := 0;
    checks := opts.DimensionIntersectionAttempts;
    --print lowerBound;        
    while upperBound - lowerBound >1 do (
        mid = floor ((upperBound+lowerBound)/2);
        --L := ideal random(S1^1,S1^{mid-1:-1});        
        L := apply(checks, tz -> ideal random(S1^1,S1^{mid-1:-1}));        
        --print ("L: "|toString(L));
        Is := {ideal(1_S1)}; 
        i = 0;
        varList := random gens S1;
        --while (Is == ideal(1_S1)) and (i < #varList) do (
        while all(Is, tz -> (tz == ideal(1_S1))) and (i < #varList) do (
            mySat := ideal(varList#i); --ideal((gens S1)#(random(#gens S1)));
            --Is = saturate(I1+L, mySat); --saturateInGenericCoordinates(I+L);
            Is = apply(L, tz -> saturate(I1 + tz, mySat));
            --print ("mySat: " | toString(mySat));            
            --print ("Is: " | toString(Is));
            i = i+1;
        );
        --print ("Is == 1: " | toString(Is == ideal 1_S1));
        if 
            all(Is, tz -> (tz == ideal(1_S1)))
        then (upperBound=mid;) else (lowerBound=mid;) ;
        --print mid
	);
    lowerBound
)



randomPoints = method(TypicalValue => List, Options => optRandomPoints);

randomPoints(ZZ, Ideal) := List => opts -> (n1, I1) ->(
    randomPointsBranching(n1, I1, opts)
);
randomPoints(Ideal) := List => opts -> (I1) ->(
    randomPointsBranching(1, I1, opts)
);


randomPointsBranching = method(TypicalValue => List, Options => optRandomPoints);

randomPointsBranching(ZZ, Ideal) := List => opts -> (n1, I) -> (
    if (opts.Verbose) or (debugLevel > 0) then print concatenate("randomPointsBranching: starting with Strategy => ", toString(opts.Strategy));
    --if they give us an ideal of a quotient ring, then 
    if (class ring I === QuotientRing) 
    then return randomPointsBranching(n1, sub(I, ambient ring I) + ideal ring I, opts);
    
    --if it is not a quotient of polynomial ring, nor a polynomial ring, then we error
    if (not class ring I === PolynomialRing) 
    then error "randomPoints: must be an ideal in a polynomial ring or a quotient thereof";
    
    genList := first entries gens I;
    R := ring I;
    if (opts.Strategy == Default) then (
        return randomPointViaDefaultStrategy(n1, I, opts)
    )
    else if (opts.Strategy == BruteForce) 
    then (
        if (opts.NumThreadsToUse > 1) then return randomPointViaMultiThreads(n1, I, opts)
        else return searchPoints(n1, R, genList, opts);
    )	
    else if (opts.Strategy == GenericProjection) 
    then return randomPointViaGenericProjection(n1, I, opts)
	
    else if (opts.Strategy == LinearIntersection) 
    then return randomPointViaLinearIntersection(n1, I, opts)

    else if (opts.Strategy == HybridProjectionIntersection) 
    then return randomPointViaGenericProjection(n1, I, opts)
    
    else if (opts.Strategy == MultiplicationTable)
    then return randomPointViaMultiplicationTable(n1, I, opts)
--    else if (opts.Strategy == LinearProjection) 
--    then return randomPointViaLinearProjection(I, opts)
    --else if (opts.Strategy == MultiThreads)
    --then return randomPointViaMultiThreads(I, opts)
    
    else error "randomPoints:  Not a valid Strategy";
);


randomPointViaMultiThreads = method(TypicalValue => List, Options => optRandomPoints);
randomPointViaMultiThreads(ZZ, Ideal) := List => opts -> (toFind, I) -> (
    if (debugLevel > 0) or (opts.Verbose) then print "randomPointViaMultiThreads: starting";
    genList := first entries gens I;
    R := ring I;
    K := coefficientRing R;
    n := #gens R;
    
    local found;
    local resultList;
    pointList := {};
    
    local numPointsToCheck;
    numPointsToCheck = floor(opts.PointCheckAttempts / opts.NumThreadsToUse); 
    
--    if opts.NumThreadsToUse > allowableThreads
--    then error "mtSearch: Not enough allowed threads to use";
    
    local flag;
    flag = new MutableList from apply(opts.NumThreadsToUse, i->0);
    
    taskList := apply(opts.NumThreadsToUse, (i)->(return createTask(mtSearchPoints, (toFind, numPointsToCheck, genList, {i,flag}, opts));));
    apply(taskList, t -> schedule t);
    while true do (
	    nanosleep 1000000; --one thousandth of a second
        if (all(taskList, t -> isReady(t))) then break;
    );
      
    resultList = apply(taskList, t -> taskResult(t));
    apply(#resultList, i -> pointList = pointList|(resultList#i));
 -*   
    if any(resultList, (l) -> (#l>0))
    then (
        j := 0;
        while #(resultList#j) == 0 do j = j + 1;
        return resultList#j;
    );
*-
    return pointList;
);

--some helper functions for randomPointViaMultiThreads

getAPoint = (n, K) -> (toList apply(n, (i) -> random(K)));

evalAtPoint = (kk, myMatrix, curPoint) -> (
    sourceRing := ring myMatrix;
    newPhi := map(kk, sourceRing, apply(curPoint, t -> sub(t, kk)));
    return newPhi(myMatrix)
);


evalAtPointIsZero = (R, genList, point) -> (
    K := coefficientRing R;
    n := #gens R;
    eval := map(K, R, point);
    for f in genList do ( 
    	if not eval(f) == 0 
	    then return false;
	);
    return true;
);

--a brute force function for multithreads
mtSearchPoints = method(Options => optRandomPoints);
mtSearchPoints(ZZ, ZZ, List, List) := opts -> (toFind, nn, genList, flagList) -> (
    if (debugLevel > 0) or (opts.Verbose) then (print "mtSearchPoints: starting thread #" | toString(nn));
    thNum := flagList#0;
    flag := flagList#1;
    local point;
    pointList := {};
    R := ring(genList#0);
    K := coefficientRing R;
    n := #gens R;
    i := 0;
    myMod := ceiling(nn/20);
    while (i < nn) do (
        if (i%(myMod) == 0) and (sum toList flag >= toFind) then break;
	    point = getAPoint(n, K);
	    --if verifyPoint(point, genList, opts)  --
        if evalAtPointIsZero(R, genList, point) and not (opts.Homogeneous and all(point, t -> t == 0))
	    then (
	        flag#thNum = flag#thNum+1;
            pointList = append(pointList, point);
	    );
        i = i+1;
	);
    return pointList;
);

--a brute force point search tool
searchPoints = method(Options => optRandomPoints);
searchPoints(ZZ, Ring, List) := opts -> (nn, R, genList) -> (
    local point;
    K := coefficientRing R;
    n := #gens R;
    pointList := {};
    i := 0;
    while (i < opts.PointCheckAttempts) and (#pointList < nn) do (
	    point = getAPoint(n, K);
	    if evalAtPointIsZero(R, genList, point) then (
            if not ((opts.Homogeneous) and (matrix{point} == 0)) then pointList = append(pointList, point);
        );
        i = i+1;
	);
    return pointList;
);



findANonZeroMinor = method(Options => optFindANonZeroMinor);

findANonZeroMinor(ZZ, Matrix, Ideal) := opts -> (n,M,I)->(
    P := {};
    local kk; 
    local kk2;
    local R;
    local phi;
    local N; local N1; local N2; local N1new; local N2new;
    local J; local Mcolumnextract; local Mrowextract;
    R = ring I;
    kk = coefficientRing R;
    i := 0;
    rk := -1;
    mutOptions := new MutableHashTable from opts;
    remove(mutOptions, MinorPointAttempts);
    ptOpts := new OptionTable from mutOptions;
    while (i < opts.MinorPointAttempts) and (rk < n) do (
        if opts.Verbose then print concatenate("findANonZeroMinor: Finding a point on the given ideal, attempt #", toString i);
        P = randomPoints(I, ptOpts);
        if #P > 0 then (
            P = P#0;
            if opts.Verbose then print concatenate("findANonZeroMinor: Found a point over the ring ", toString(kk2));
            kk2 = ring P#0;            
            phi =  map(kk2,R,sub(matrix{P},kk2));    
            N = mutableMatrix phi(M);
            rk = rank(N);
            if opts.Verbose and  (rk < n) then print "findANonZeroMinor: The matrix didn't have the desired rank at this point.  We may try again";
        )
        else(
            if opts.Verbose then print concatenate("findANonZeroMinor: Failed to find a point, we may try again.");
        );
        i = i+1;
    );    
    if (rk < n) then error "findANonZeroMinor: All minors of given size vanish at the randomly chosen points. You may want to increase MinorPointAttempts, or change Strategy.";    
    if opts.Verbose then print "findANonZeroMinor:  The point had full rank.  Now finding the submatrix.";
    N1 = (columnRankProfile(N));
    Mcolumnextract = M_N1;
    M11 := mutableMatrix phi(Mcolumnextract);
    N2 = (rowRankProfile(M11));
    N1rand := random(N1);
    N1new = {};
    for i from  0 to n-1 do(
	    N1new = join(N1new, {N1rand#i});
    );
    M3 := mutableMatrix phi(M_N1new);
    --Karl:  I modified the following.
    if (rank(M3)<n) then error "findANonZeroMinor:  Something went wrong, the matrix rank fell taking the first submatrix.  This indicates a bug in the program.";
    --this is what was written before:
    --return (P,N1,N2,"findANonZeroMinor: Using the the second and third outputs failed to generate a random matrix of the given size, that has full rank when evaluated at the first output.");
    N2rand := random(rowRankProfile(M3));
    N2new = {};
    for i from 0 to n-1 do(
        N2new = join(N2new, {N2rand#i});
    );
    Mspecificrowextract := (M_N1new)^N2new;
    return (P, N1, N2, Mspecificrowextract);	
);

extendIdealByNonZeroMinor = method(Options=>optFindANonZeroMinor);
extendIdealByNonZeroMinor(ZZ,Matrix,Ideal):= opts -> (n, M, I) -> (
    local O;  
    local Ifin;
    O = findANonZeroMinor(n,M,I,opts); 
    L1 := ideal (det(O#3));
    Ifin = I + L1;
    return Ifin;
);





---


-- A function with an optional argument


beginDocumentation()
document {
        Key => RandomPointsOld,
        Headline => "Obtain random points in a variety",
        EM "RandomPoints", "Find random points inside a variety.",
        BR{},BR{},
        "This package provides tools for quickly finding a point (rational, or over a field extension) in the vanishing set of an ideal.  The search is highly customizable.  This package also includes tools for finding submatrices of a given rank at some point.  Furthermore, it provides tools for generic projections and producing collections of linear forms with specified properties.",
        BR{},
        BOLD "Core functions:",
        UL {
            {TO "randomPoints", ":  This tries to find a point in the vanishing set of an ideal."},
            {TO "findANonZeroMinor", ":  This finds a submatrix of a given matrix that is nonsingular at a point of a given ideal."},            
            {TO "extendIdealByNonZeroMinor", ":  This extends an ideal by a minor produced by ", TO "findANonZeroMinor", "."},
            {TO "projectionToHypersurface", " and ", TO "genericProjection", ":  These functions provide customizable projection."}
	    },
        BR{},BR{},
	    BOLD "Acknowledgements:",BR{},BR{},
	    "The authors would like to thank David Eisenbud and Mike Stillman for useful conversations and comments on the development of this package.  The authors began work on this package at the virtual Cleveland 2020 Macaulay2 workshop."
}



doc ///
    Key
        getRandomLinearForms
        (getRandomLinearForms, Ring, List)
        [getRandomLinearForms, Verify]
        [getRandomLinearForms, Homogeneous]
        [getRandomLinearForms, Verbose]
    Headline
        retrieve a list of random degree 1 and 0 forms of specified types
    Usage
        getRandomLinearForms(R, L)
    Inputs
        R:Ring
            the ring where the forms should live
        L:List
            a list with 6 entries, each a number of types of forms.  Constant forms, monomial forms (plus a constant term if {\tt Homogeneous => false}), monomial forms, binomial forms, trinomial forms, and random forms.
        Verify => Boolean
            whether to check if the output linear forms have Jacobian of maximal rank
        Verbose => Boolean
            turn on or off verbose output
        Homogeneous => Boolean
            allows constant terms on some linear forms if true
    Outputs
        :List
            a list of random forms of the specified types
    Description
        Text
            This will give you a list of random forms (ring elements) of the specified types.  This is useful, because in many cases, for instance when doing generic projection, you only need a a certain number of the forms in the map to be fully random.  Furthermore, at the cost of some randomness, using monomial or binomial forms can be much faster.            

            The types of form are specified via the second argument, a list with 5 entries.  The first entry is how many constant forms are allowed.
        Example
            R = ZZ/31[a,b,c]
            getRandomLinearForms(R, {2,0,0,0,0,0})
        Text
            The second entry in the list is how many monomial forms are returned.  Note if {\tt Homogeneous=>false} then these forms will usually have constant terms.
        Example
            getRandomLinearForms(R, {0,2,0,0,0,0}, Homogeneous=>true)
            getRandomLinearForms(R, {0,2,0,0,0,0}, Homogeneous=>false)
        Text
            Next, the third entry is how many monomial forms (without constant terms, even if {\tt Homogeneous=>false}).
        Example
            getRandomLinearForms(R, {0,0,2,0,0,0}, Homogeneous=>false)
        Text
            The fourth entry is how many binomial forms should be returned.
        Example
            getRandomLinearForms(R, {0,0,0,1,0,0}, Homogeneous=>true)
            getRandomLinearForms(R, {0,0,0,1,0,0}, Homogeneous=>false)
        Text
            The ultimate entry is how many truly random forms to produce.
        Example
            getRandomLinearForms(R, {0,0,0,0,0,1}, Homogeneous=>true)
            getRandomLinearForms(R, {0,0,0,0,0,1}, Homogeneous=>false)
        Text
            You may combine the different specifications to create a list of the desired type.  The order is randomized.

            If the option {\tt Verify=>true}, then this will check the jacobian of the list of forms (discounting the constant forms), to make sure it has maximal rank.  Random forms in small numbers of variables over small fields will produce non-injective ring maps occasionally otherwise.        
///

doc ///
    Key
        Codimension
        [extendIdealByNonZeroMinor, Codimension]
        [findANonZeroMinor, Codimension]
        [randomPointViaLinearIntersection, Codimension]        
    Headline
        an option to specify the codimension so as not to compute it
    Usage
        Codimension => n
    Inputs
        n:ZZ
            an integer, or null
    Description
        Text
            Various functions need to know the codimension/height of the scheme/ideal it is working with.  Setting this to be an integer will tell the function not to compute the codimension and to use this value instead.  The default value is {\tt null}, in which case the function will compute the codimension.
///

doc ///
    Key
        ExtendField
        [randomPoints, ExtendField]
        [findANonZeroMinor, ExtendField]      
        [extendIdealByNonZeroMinor, ExtendField]  
    Headline
        an option used to specify if extending the finite field is permissable here
    Usage
        ExtendField => b
    Inputs
        b:Boolean
            whether the base field is allowed to be extended
    Description
        Text
            Various functions which produce points, or call functions which produce points, may naturally find scheme theoretic points that are not rational over the base field (for example, by intersecting with a random linear space).  Setting {\tt ExtendField => true} will tell the function that such points are valid.  Setting {\tt ExtendField => false} will tell the function ignore such points.  This sometimes can slow computation, and other times can speed it up.  In some cases, points over extended fields may also have better randomness properties for applications.
    SeeAlso
        randomPoints
        findANonZeroMinor
        extendIdealByNonZeroMinor
///

doc ///
    Key
        genericProjection
        (genericProjection, Ideal)
        (genericProjection, Ring)
        (genericProjection, ZZ, Ideal)
        (genericProjection, ZZ, Ring)
        [genericProjection, Homogeneous]
    Headline
       finds a random (somewhat) generic projection of the ring or ideal
    Usage
        genericProjection(n, I)
        genericProjection(n, R)
        genericProjection(I)
        genericProjection(R)
    Inputs
        I:Ideal 
            in a polynomial ring
        R:Ring
            a quotient of a polynomial ring
        n:ZZ
            an integer specifying how many dimensions to drop
        MaxCoordinatesToReplace => ZZ
            to be passed to randomCoordinateChange
        Replacement => Symbol
            to be passed to randomCoordinateChange
        Homogeneous => Boolean
            to be passed to randomCoordinateChange
    Outputs
        :List
            a list with two entries, the generic projection map, and the ideal if I was provided, or the ring if R was provided
    Description
        Text
            This gives the projection map from $\mathbb{A}^N \mapsto\mathbb{A}^{N-n}$ and the defining ideal of the projection of $V(I)$
        Example
            R=ZZ/5[x,y,z,w];
            I = ideal(x,y^2,w^3+x^2);
            genericProjection(2,I)
        Text
            If no integer $n$ is provided, then drops one dimension, in other words it treats $n = 1$.
        Example
            R=ZZ/5[x,y,z,w];
            I = ideal(x,y^2);
            genericProjection(I)
        Text
            Alternately, instead of {\tt I}, you may pass it a quotient ring.  It will then return the inclusion of the generic projection ring into the given ring, followed by the source of that inclusion.  It is essentially the same functionality as calling {\tt genericProjection(n, ideal R)} although the format of the output is slightly different.
        Example
            R = ZZ/13[x,y,z];
            I = ideal(y^2*z-x*(x-z)*(x+z));
            genericProjection(R/I)
        Text
            This method works by calling {\tt randomCoordinateChange} before dropping some variables.  It passes the options {\tt Replacement}, {\tt MaxCoordinatesToReplace}, {\tt Homogeneous} to that function.
        Text
            This function makes no attempt to verify that the projection is actually generic with respect to the ideal.  
    SeeAlso
        randomCoordinateChange
///

doc ///
    Key
        randomCoordinateChange
        (randomCoordinateChange, Ring)
        [randomCoordinateChange, Homogeneous]
    Headline
        produce linear automorphism of the ring
    Usage
        randomCoordinateChange R
    Inputs
        R:Ring
            a polynomial Ring
        MaxCoordinatesToReplace => ZZ 
            how many coordinates should be replaced by linear functions
        Replacement => Symbol 
            whether coordinate replacements should be binomial (Binomial) or fully random (Full) 
        Homogeneous => Boolean
            whether coordinate replacements should be Homogeneous
        Verbose => Boolean
            set to true for verbose output
    Outputs
        :RingMap
            the coordinate change map.
    Description
        Text
            Given a polynomial ring, this will produce a linear automorphism of the ring. 
        Example
            R=ZZ/5[x,y,z]
            randomCoordinateChange(R)
        Text
            In some applications, a full change of coordinates is not desired, as it might cause code to run slowly, and so a Binomialr change of coordinates might be preferred.  
            These Binomial changes of coordinates can be accomplished with the options {\tt Replacement} and {\tt MaxCoordinatesToReplace}.
            {\tt Replacement} can take either {\tt Binomial} or {\tt Full}.  If {\tt Binomial} is specified, then only binomial changes of coordinates will be produced. 
        Example
            S = ZZ/11[a..e]
            randomCoordinateChange(S, Replacement=>Binomial)
        Text
            Finally, if {\tt Homogeneous} is set to {\tt false}, then our change of coordinates is not homogeneous (although it is still linear).
        Example 
            randomCoordinateChange(R, Homogeneous=>false)
        Text
            Note, this function already checks whether the function is an isomorphism by computing the Jacobian.
///

doc ///
    Key
        [genericProjection, Verbose]
        [randomCoordinateChange, Verbose]
        [randomPoints, Verbose]
        [projectionToHypersurface, Verbose]
    Headline
        turns out Verbose (debugging) output
    Description
        Text
            Set the option {\tt Verbose => true} to turn on verbose output.  This may be useful in debugging or in determining why an computation is running slowly. 
///

doc ///
    Key
        projectionToHypersurface
        (projectionToHypersurface, Ideal)
        (projectionToHypersurface, Ring)
        [projectionToHypersurface, Codimension]
        [projectionToHypersurface, Homogeneous]
    Headline
        Generic projection to a hypersurface
    Usage
        projectionToHypersurface I
        projectionToHypersurface R 
    Inputs
        I:Ideal
            an ideal in a polynomial ring
        R:Ring
            a quotient of a polynomial ring
        Codimension => ZZ
            specified if you already know the codimension of your Ideal (or QuotientRing) in your ambient ring
        MaxCoordinatesToReplace => ZZ
            to be passed to randomCoordinateChange
        Replacement => Symbol
            to be passed to randomCoordinateChange
        Homogeneous => Boolean
            to be passed to randomCoordinateChange
        Verbose => Boolean
            set to true for verbose output
    Outputs
        :RingMap
            a list with two entries, the generic projection map, and the ideal if {\tt I} was provided, or the ring if {\tt R} was provided
    Description
        Text
            This creates a projection to a hypersurface.  It differs from {\tt genericProjection(codim I - 1, I)} as it only tries to find a hypersurface equation that vanishes along the projection, instead of finding one that vanishes exactly at the projection.  This can be faster, and can be useful for finding points.
        Example
            R=ZZ/5[x,y,z];
            I = ideal(random(3,R)-2, random(2,R));
            projectionToHypersurface(I)
            projectionToHypersurface(R/I)
        Text
            If you already know the codimension is {\tt c}, you can set {\tt Codimension=>c} so the function does not compute it.
    SeeAlso
        genericProjection
///

doc///
    Key
        ProjectionAttempts
        [randomPoints, ProjectionAttempts]
        [extendIdealByNonZeroMinor, ProjectionAttempts]
        [findANonZeroMinor, ProjectionAttempts]
    Headline
         Number of projection trials using in randomPoints when doing generic projection
    Description
        Text
            When calling the Strategy {\tt GenericProjection} or {\tt HybridProjectionIntersection} from {\tt randomPoints}, this option denotes the number of trials before giving up.  This option is also passed to randomPoints by other functions.
    SeeAlso
        randomPoints
///


doc ///
    Key
        IntersectionAttempts
        [randomPoints, IntersectionAttempts]
        [extendIdealByNonZeroMinor, IntersectionAttempts]
        [findANonZeroMinor, IntersectionAttempts]
    Headline
        an option which controls how many linear intersections are attempted when looking for rational points
    Usage
        IntersectionAttempts => n
    Inputs
        n:ZZ
            the maximum attempts to make
    Description
        Text
            This option is used by {\tt randomPoints} in some strategies to determine the maximum number of attempts to intersect with a linear space when looking for random rational points.  Other functions pass this option through to {\tt randomPoints}.
    
///

doc///
    Key
        MaxCoordinatesToReplace
        [randomCoordinateChange, MaxCoordinatesToReplace]
        [randomPoints, MaxCoordinatesToReplace]
        [genericProjection, MaxCoordinatesToReplace]
        [extendIdealByNonZeroMinor, MaxCoordinatesToReplace]
        [findANonZeroMinor, MaxCoordinatesToReplace]        
        [projectionToHypersurface, MaxCoordinatesToReplace]        
    Headline
        The maximum number of coordinates to turn into non-monomial functions when calling {\tt randomCoordinateChange}
    Description
        Text
            When calling {\tt randomCoordinateChange}, the user can specify that only a specified number of coordinates should be non-monomial.  Sometimes, generic coordinate changes where all coordinates are modified, can be very slow.  This is a way to mitigate for that.
            This option is passed to {\tt randomCoordinateChange} by other functions that call it.
        Example
            S = ZZ/11[a..e]
            randomCoordinateChange(S, MaxCoordinatesToReplace=>2)
    SeeAlso
        randomCoordinateChange
///

doc ///
    Key
        Replacement
        [randomCoordinateChange, Replacement]
        [genericProjection, Replacement]
        [projectionToHypersurface, Replacement]
        [findANonZeroMinor, Replacement]
        [randomPoints, Replacement]
        [extendIdealByNonZeroMinor, Replacement]
        Full
    Headline
        When changing coordinates, whether to replace variables by general degre 1 forms or binomials
    Usage
        Replacement => Full
        Replacement => Binomial
    Description
        Text
            When calling {\tt randomCoordinateChange}, or functions that call it, setting {\tt Replacement => Full} will mean that coordinates are changed to a general degree 1 form.  If {\tt Replacement => Binomial}, the coordiates are only changed to bionomials, which can be much faster for certain applications.
        Example
            R = ZZ/11[a,b,c];
            randomCoordinateChange(R, Replacement=>Full)
            randomCoordinateChange(R, Replacement=>Binomial)
        Text
            If {\tt Homogeneous => false}, then there will be constant terms, and we view $mx + b$ as a binomial.
        Example
            S = ZZ/11[x,y];
            randomCoordinateChange(S, Replacement => Full, Homogeneous => false)
            randomCoordinateChange(S, Replacement => Binomial, Homogeneous => false)
    SeeAlso
        randomCoordinateChange
///

doc ///
    Key
        [randomPoints, Strategy]
        [findANonZeroMinor, Strategy]
        [extendIdealByNonZeroMinor, Strategy]
        Default
        BruteForce
        GenericProjection
        LinearIntersection
        HybridProjectionIntersection
        MultiplicationTable
    Headline
        values for the option Strategy when calling randomPoints
    Description
        Text
            When calling {\tt randomPoints}, set the strategy to one of these.
            {\tt BruteForce} simply tries random points and sees if they are on the variety.
	    
            {\tt GenericProjection} projects to a hypersurface, via {\tt projectionToHypersurface} and then uses a {\tt BruteForce} strategy.
	    
            {\tt LinearIntersection} intersects with an appropriately random linear space.
	    
            {\tt HybridProjectionIntersection} does a generic projection, followed by a linear intersection. Notice that speed, or success, varies depending on the strategy.

            {\tt Default} performs a sequence of different strategies, depending on the context.

            {\tt MultiplicationTable} works for homogeneous ideals only. It computes the dimension of $I$ probabilistically, speeding up
            the process. It cuts down with a linear space to a zero-dimensional projective scheme and computes how the last two variables act on the quotient ring truncated  
            at the regularity. In case of an absolutely irreducible $I$ over the field, we will find with  high probability a point, 
            since the determinant will have a linear factor in at least 50% of the cases.  
    SeeAlso
        randomPoints
        randomKRationalPoint
        projectionToHypersurface
///

-*doc///
    Key
        Codimension
        [randomPoints, Codimension]
        [projectionToHypersurface, Codimension]
    Headline
        Checks the 
    Description 
        Text
            
    SeeAlso
        randomPoints
        projectionToHypersurface
///
*-
doc///
    Key 
        NumThreadsToUse
        [randomPoints, NumThreadsToUse]
        [extendIdealByNonZeroMinor, NumThreadsToUse]
        [findANonZeroMinor, NumThreadsToUse]
    Headline
        number of threads the the function will use in a brute force search for a point 
    Description
        Text
            When calling {\tt randomPoints}, and functions that call it, with a {\tt BruteForce} strategy, this denotes the number of threads to use in brute force point checking.
    Caveat
        Currently multi threading creates instability.  Use at your own risk.
    SeeAlso
        randomPoints
///

doc///
    Key 
        PointCheckAttempts
        [randomPoints, PointCheckAttempts]
        [extendIdealByNonZeroMinor,PointCheckAttempts ]
        [findANonZeroMinor, PointCheckAttempts]
    Headline
        Number of times the the function will search for a point 
    Description
        Text
            When calling {\tt randomPoints}, and functions that call it, with a {\tt BruteForce} strategy or {\tt GenericProjection} strategy, this denotes the number of trials for brute force point checking.
        Example
            R = ZZ/11[x,y,z];
            I = ideal(x,y);
            randomPoints(I, PointCheckAttempts=>1)
            randomPoints(I, PointCheckAttempts=>1000)
    SeeAlso
        randomPoints
        extendIdealByNonZeroMinor
        findANonZeroMinor
///

doc ///
    Key
        MaxCoordinatesToTrivialize
        [extendIdealByNonZeroMinor, MaxCoordinatesToTrivialize]
        [findANonZeroMinor, MaxCoordinatesToTrivialize]
        [randomPoints, MaxCoordinatesToTrivialize]
    Headline
        the number of coordinates to set to random values when doing a linear intersection
    Description
        Text
            When calling {\tt randomPoints} and performing an intersection with a linear space, this is the number of defining equations of the linear space of the form $x_i - a_i$.  Having a large number of these will provide faster intersections.
///

doc ///
    Key
        randomPoints
        (randomPoints, Ideal)
        (randomPoints, ZZ, Ideal)
        [randomPoints, Homogeneous]        
        [randomPoints, Codimension]
        [randomPoints, DimensionFunction]
    Headline
        a function to find random points  in a variety. 
    Usage
        randomPoints(I) 
        randomPoints(n, I)        
    Inputs
        n: ZZ
            an integer denoting the number of desired points.
        I:Ideal
            inside a polynomial ring.
        R:Ring
            a polynomial ring
        Strategy => Symbol
            to specify which strategy to use, Default, BruteForce, LinearIntersection, GenericProjection, HybridProjectionIntersection, MultiplicationTable.
        ProjectionAttempts => ZZ
            see @TO ProjectionAttempts@
        MaxCoordinatesToReplace => ZZ
            see @TO MaxCoordinatesToReplace@
        Codimension => ZZ
            see @TO Codimension@
        ExtendField => Boolean
            whether to allow points not rational over the base field
        IntersectionAttempts => ZZ
            see @TO IntersectionAttempts@
	    PointCheckAttempts => ZZ
	        points to search in total, see @TO PointCheckAttempts@
        NumThreadsToUse => ZZ
	        number of threads to use in the BruteForce strategy, see @TO NumThreadsToUse@
        DimensionFunction => Function
            specify a custom dimension function, such as the default dimViaBezout or the Macaulay2 function dim
    Outputs
        :List
            a list of points in the variety with possible repetitions.
    Description
        Text  
           Gives at most $n$ many point in a variety $V(I)$. 
        Example
            R = ZZ/5[t_1..t_3];
            I = ideal(t_1,t_2+t_3);
            randomPoints(3, I)
            randomPoints(4, I, Strategy => Default)            
            randomPoints(4, I, Strategy => LinearIntersection)
        Text 
            Using the MultiplicationTable Strategy is sometimes faster:
        Example
            S=ZZ/103[y_0..y_14];
            I=minors(2,random(S^3,S^{5:-1}));
            elapsedTime randomPoints(I,Strategy=>MultiplicationTable, Codimension=>8)
            elapsedTime randomPoints(I,Codimension=>8)
        Text
            and other times not:
        Example
            S=ZZ/101[y_0..y_9];
            I=ideal random(S^1,S^{-2,-2,-2,-3})+(ideal random(2,S))^2;
            elapsedTime randomPoints(I,Strategy=>MultiplicationTable,Codimension=>5)
            elapsedTime randomPoints(I,Codimension=>5)
///

doc ///
    Key
        dimViaBezout
        (dimViaBezout, Ideal)
        [dimViaBezout, DimensionIntersectionAttempts]
        [dimViaBezout, MinimumFieldSize]
        [dimViaBezout, Verbose]
        [dimViaBezout, Homogeneous]
        MinimumFieldSize
        DimensionIntersectionAttempts        
    Headline
        computes the dimension of the given ideal $I$ probabilistically
    Usage
        dimViaBezout(I)
    Inputs
        I: Ideal
            in a polynomial ring over a field
        DimensionIntersectionAttempts => ZZ
            the number of linear spaces to try before moving to the next dimension
        MinimumFieldSize => ZZ
            if the ambient field is smaller than this value it will automatically be replaced with an extension
    Outputs
        : ZZ
            d = dimension of the ideal $I$
    Description
        Text
            This intersects $V(I)$ with successively higher dimensional random linear spaces until there is an intersection.  For example, if $V(I)$ intersect a random line has a point, then we expect that $V(I)$ contains a hypersurface.  If there was no intersection, this function tries a 2-dimensional linear space, and so on.  This speeds up many computations.
        Example
            kk=ZZ/nextPrime 10^2;
            S=kk[y_0..y_14];
            I=minors(2,random(S^3,S^{5:-1}));
            elapsedTime dimViaBezout(I)
            elapsedTime dim I
        Text
            The user may set the {\tt MinimumFieldSize} to ensure that the field being worked over is big enough.  For instance, there are relatively few linear spaces over a field of characteristic 2, and this can cause incorrect results to be provided. 
        Text
            This function computes things in two ways, depending on if the ideal is homogeneous or not.  If you wish to force non-homogeneous computation, set the option {\tt Homogeneous=false}.  This can be faster in some examples.
    SeeAlso
        DimensionFunction
///

doc ///
    Key
        DimensionFunction
    Headline
        an option for specifying custom dimension functions
    Usage
        DimensionFunction => myFunction
    Description
        Text
            This package provides a custom dimension function for probabilistically computing the dimension, {\tt dimViaBezout}.  However, in some cases this can be substantially slower than calling the built in function {\tt dim}.  Thus the user may switch to using the built in function, or their own custom dimension function, via the option {\tt DimensionFunction => ...}.
    SeeAlso
        dim
        dimViaBezout
///

doc ///
    Key
        findANonZeroMinor
        (findANonZeroMinor, ZZ, Matrix, Ideal)
        [findANonZeroMinor, Verbose]
        [findANonZeroMinor, Homogeneous]        
        [findANonZeroMinor, MinorPointAttempts]
        [findANonZeroMinor, DimensionFunction]
        MinorPointAttempts
    Headline
        finds a non-vanishing minor at some randomly chosen point 
    Usage
        findANonZeroMinor(n,M,I)        
    Inputs
        I: Ideal
            in a polynomial ring over QQ or ZZ/p for p prime 
        M: Matrix
            over the polynomial ring
        n: ZZ
            the size of the minors to consider
        Strategy => Symbol
            to specify which strategy to use when calling @TO randomPoints@
        Verbose => Boolean
            set to true for verbose output
        Homogeneous => Boolean
            controls if the computations are homogeneous (in calls to {\tt randomPoints})
        MinorPointAttempts => ZZ
            how many points to check the rank of the matrix at
        DimensionFunction => Function
            specify a custom dimension function, such as the default dimViaBezout or the Macaulay2 function dim       
    Outputs
        : Sequence
            The functions outputs the following:
            
            1. randomly chosen point $P$ in $V(I)$, 
            
            2. the indexes of the columns of $M$ that stay linearly independent upon plugging $P$ into $M$, 

            3. the indices of the linearly independent rows of the matrix extracted from $M$ using (2), 

            4. a random $n\times n$ submatrix of $M$ that has full rank at $P$.
    Description
        Text
            Given an ideal, a matrix, an integer and a user defined Strategy, this function uses the 
            {\tt randomPoints} function to find a point in 
            $V(I)$. Then it plugs the point in the matrix and tries to find
            a non-zero  minor of size equal to the given integer. It outputs the point and also one of the submatrices of interest
            along with the column and row indices that were used sequentially.              
        Example
            R = ZZ/5[x,y,z];
            I = ideal(random(3,R)-2, random(2,R));
            M = jacobian(I);
            findANonZeroMinor(2,M,I)
        Text
            The option {\tt MinorPointAttempts} is how many points to attempt before giving up.
    SeeAlso
        randomPoints
///


doc ///
    Key
        extendIdealByNonZeroMinor
        (extendIdealByNonZeroMinor, ZZ, Matrix, Ideal)
        [extendIdealByNonZeroMinor, Homogeneous]        
        [extendIdealByNonZeroMinor, MinorPointAttempts]        
        [extendIdealByNonZeroMinor, Verbose]        
        [extendIdealByNonZeroMinor, DimensionFunction]        
    Headline
        extends the ideal to aid finding singular locus
    Usage
        extendIdealByNonZeroMinor(n,M,I)        
    Inputs
        I: Ideal
            in a polynomial ring over QQ or ZZ/p for p prime 
        M: Matrix
            over the polynomial ring
        n: ZZ
            the size of the minors to consider            
        Strategy => Symbol
            specify which strategy to use when calling @TO randomPoints@
        Homogeneous => Boolean
            controls if the computations are homogeneous (in calls to {\tt randomPoints})
        Verbose => Boolean
            turns on or off verbose output
        MinorPointAttempts => ZZ
            how many points to check the rank of the matrix at     
        DimensionFunction => Function
            specify a custom dimension function, such as the default dimViaBezout or the Macaulay2 function dim       
    Outputs
        : Ideal
            the original ideal extended by the determinant of 
            the non vanishing minor found
    Description
        Text
            This function finds a submatrix of size $n\times n$ using {\tt findANonZeroMinor};  
            it extracts the last entry of the output, finds its determinant and
            adds it to the ideal $I$, thus extending $I$.
        Example
            R = ZZ/5[x,y,z];
            I = ideal(random(3,R)-2, random(2,R));
            M = jacobian(I);
            extendIdealByNonZeroMinor(2,M,I, Strategy => LinearIntersection)
        Text
            One use for this function can be in showing a certain rings are R1 (regular in codimension 1).  Consider the following example which is R1 where computing the dimension of the singular locus takes around 30 seconds as there are 15500 minors of size $4 \times 4$ in the associated $7 \times 12$ Jacobian matrix.  However, we can use this function to quickly find interesting minors.  
        Example
            T = ZZ/101[x1,x2,x3,x4,x5,x6,x7];
            I =  ideal(x5*x6-x4*x7,x1*x6-x2*x7,x5^2-x1*x7,x4*x5-x2*x7,x4^2-x2*x6,x1*x4-x2*x5,x2*x3^3*x5+3*x2*x3^2*x7+8*x2^2*x5+3*x3*x4*x7-8*x4*x7+x6*x7,x1*x3^3*x5+3*x1*x3^2*x7+8*x1*x2*x5+3*x3*x5*x7-8*x5*x7+x7^2,x2*x3^3*x4+3*x2*x3^2*x6+8*x2^2*x4+3*x3*x4*x6-8*x4*x6+x6^2,x2^2*x3^3+3*x2*x3^2*x4+8*x2^3+3*x2*x3*x6-8*x2*x6+x4*x6,x1*x2*x3^3+3*x2*x3^2*x5+8*x1*x2^2+3*x2*x3*x7-8*x2*x7+x4*x7,x1^2*x3^3+3*x1*x3^2*x5+8*x1^2*x2+3*x1*x3*x7-8*x1*x7+x5*x7);
            M = jacobian I;
            i = 0;
            J = I;
            elapsedTime(while (i < 10) and dim J > 1 do (i = i+1; J = extendIdealByNonZeroMinor(4, M, J)) );
            dim J
            i
        Text
            In this particular example, there tend to be about 5 associated primes when adding the first minor to J, and so one would expect about 5 steps as each minor computed most likely will eliminate one of those primes.
        Text
            There is some similar functionality obtained via heuristics (as opposed to actually finding rational points) in the package "FastMinors".
    SeeAlso
        findANonZeroMinor
///

 ----- TESTS -----

--this test tests ....
TEST/// 
R=ZZ/5[x,y,z,w];
I = ideal(x,y^2,w^3+x^2);
genericProjection(2,I);
--assert(map)
///

--testing randomCoordinateChange with Homogeneous => true
TEST///
R = QQ[x,y,z,w];
phi = randomCoordinateChange(R, Homogeneous=>true);
m = ideal(x,y,z,w);
S = source phi;
n = sub(m, S);
assert(preimage(phi, m) == n);  --if we are homogeneous, this should be true
assert(phi(n) == m);
///

--testing randomCoordinateChange with Homogeneous => false
TEST ///
R = ZZ/1031[x,y,z,u,v,w];
phi = randomCoordinateChange(R, Homogeneous => false);
m = ideal(x,y,z);
S = source phi;
n = sub(m, S);
assert(dim phi(n) == dim m);
assert(dim preimage(phi, m) == dim n);
assert(preimage(phi, m) != n); --there is a theoretical chance this could happen, about 1 in 10^18.
assert(phi(n) != m);
///

--testing randomCoordinateChange with MaxCoordinatesToReplace => 0
TEST ///
R = ZZ/11[x,y,z];
phi = randomCoordinateChange(R, MaxCoordinatesToReplace => 0);
M = matrix phi;
S1 = set first entries M;
S2 = set gens R;
assert(isSubset(S1, S2) and isSubset(S2, S1));
///

--verifying Binomial vs Full replacement
TEST ///
R = ZZ/1031[a..h];
phi = randomCoordinateChange(R, Replacement=>Binomial);
psi = randomCoordinateChange(R, Replacement=>Full);
assert(all(apply(first entries matrix phi, v -> terms v), t -> #t <= 2));
assert(any(apply(first entries matrix psi, v -> terms v), t -> #t >= 3)); --this could be false, and an asteroid could destroy Earth.
///

--testing genericProjection, on an ideal
TEST///
R = ZZ/101[a,b,c];
I = ideal(a,b,c);
L = genericProjection(2, I, Homogeneous => true);
assert(dim source (L#0) == 1);
assert(dim (L#1) == 0);  
L2 = genericProjection(I, Homogeneous => true);
assert(dim source (L2#0) == 2);
assert(dim (L2#1) == 0);  
L3 = genericProjection(2, I, Homogeneous => false)
assert(dim (L3#1) == 0)
///

--testing genericProjection, on a ring
TEST///
R = ZZ/101[x,y,z]/ideal(y^2*z-x*(x-z)*(x+z));
L = genericProjection(1, R, Homogeneous => true); --we are already a hypersurface, so this should turn into a polynomial ring
assert(dim source (L#0) == 2);
assert(ker (L#0) == 0)
L2 = genericProjection(1, R, Homogeneous => false);
assert(dim source (L#0) == 2);
assert(ker (L2#0) == 0)
///

--testing projectionToHypersurface, for an ideal and a ring
TEST///
R = ZZ/11[x,y,z];
I = ideal(random(2, R), random(3, R));
L = projectionToHypersurface(I);
assert(dim source(L#0) == 2); --we should drop one dimension
assert(codim(L#1) == 1);
L2 = projectionToHypersurface(R/I);
assert(dim source(L2#0) == 1)
assert(codim(L2#1) == 1)
///

TEST///
---this tests findANonZeroMinor---
R = ZZ/5[x,y,z];
I = ideal(random(3,R)-2, random(2,R));
M = jacobian(I);
Output = findANonZeroMinor(2,M,I);
phi = map(ZZ/5, R, sub(matrix{Output#0},ZZ/5));
assert(det(phi(Output#3))!=0)
///


TEST///
---this tests extendIdealByNonZeroMinor---
R = ZZ/7[t_1..t_3];
I = ideal(t_1,t_2+t_3);
M = jacobian I;           
assert(dim extendIdealByNonZeroMinor(2,M,I,Strategy => LinearIntersection) < 1)
///

TEST///
---this tests whether extending the field works
R = ZZ/5[x];
I = ideal(x^2+x+1); --irreducible
assert(#randomPoints(1, I) == 0);
assert(#randomPoints(1, I, Strategy=>BruteForce) == 0);
assert(#randomPoints(1, I, ExtendField=>true) > 0);
///

TEST ///
S=ZZ/101[y_0..y_19];
I=ideal random(S^1,S^{5:-1});
assert(dimViaBezout I == dim I);

S=ZZ/103[y_0..y_20];
I=ideal random(S^1,S^{8:-1});
assert(dimViaBezout I ==dim I)
///

end

-- Here place M2 code that you find useful while developing this
-- package.  None of it will be executed when the file is loaded,
-- because loading stops when the symbol "end" is encountered.

installPackage "RandomPoints"
installPackage("RandomPoints", RemakeAllDocumentation=>true)
check RandomPoints

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/packages PACKAGES=RandomPoints pre-install"
-- End:
