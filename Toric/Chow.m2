
newPackage(
     "Chow",
     Version => "0.5",
     Date => "22 November  2009",
     Authors => {{
	       Name => "Diane Maclagan",
       	       Email => "D.Maclagan@warwick.ac.uk",
	       HomePage => "http://www.warwick.ac.uk/staff/D.Maclagan"},
	   {  Name => "Sameera Vemulapalli",
       	       Email => "sammerav@princeton.edu",
	       HomePage => ""},
	    {Name => "Corey Harris",
       	       Email => "harris@mis.mpg.de",
	       HomePage => "http://coreyharris.name"},
	   {Name => "Erika Pirnes",
	       Email => "erika.pirnes@wisc.edu",
	       HomePage => "https://sites.google.com/view/erikapirnes" }
	   },
     Headline => "Chow computations for toric varieties",
     DebuggingMode => true,
     PackageImports => {"FourierMotzkin", "Polyhedra"},
     PackageExports => {"NormalToricVarieties"}
     )

export { 
     "nefCone",
     "effCone",
     "isContainedCones",
     "chowGroupBasis",
     "chowGroup",
     "iintersectionRing",
     "ToricCycle",
     "toricCycle",
     "isTransverse"
     }

protect ChowGroupBas 
protect AmbientRing

---------------------------------------------------------------------------
-- CODE
---------------------------------------------------------------------------

--Is A contained in B?
--A, B lists
isContained = (A,B)->(
     all(A,i->member(i,B))
     )

--Index of lattice generated by rays of tau in the lattice generated by the 
--rays of the Normal ToricVariety X 
latticeIndex = (tau, X) ->(
      A:=matrix rays X;
      B:=A^tau;
      brank:=rank B;
      if brank < rank A then (
	   K:=gens kernel B;
	   C:=gens kernel transpose(A*K);
	   A=transpose(C)*A;
      );
      if not((rank A)==brank) then error("Something's wrong here");
      a:=(flatten entries mingens minors(brank,A))_0;
      b:=(flatten entries mingens minors(brank,B))_0;
      return(lift(b/a,ZZ));
)     
     
--Is cone with generators given by columns of M contained in cone generated
--by columns of N?
--Temporarily assuming full dimensional
--(ie this is a hack)
isContainedCones= (M,N) ->(
          Nfacets:=(fourierMotzkin(N))#0;
	  nonneg := flatten entries ((transpose M)* Nfacets);
	  if max(nonneg)>0 then return(false) else return(true);
);     

--Intersect the cones given by the columns of M and the columns of N
--Temporarily assuming full dimensional
--(ie this is a hack)
intersectCones=(M,N)-> (
        Nfacets:=(fourierMotzkin(N))#0;
        Mfacets:=(fourierMotzkin(M))#0;
	return( (fourierMotzkin(Nfacets | Mfacets))#0);
);	

--Chow
-- i is codim
chowGroup=(i,X) -> ( 
     if i>dim(X) then error("i > dim(X)");
     if not(X.cache.?Chow) then X.cache.Chow = new MutableHashTable;
     if not(X.cache.Chow#?i) then (
     n:=dim X;
     -- Get the faces of dim i, i-1
     sigmaCodimi := orbits(X,n-i);
     if i == 0 then (
	if #sigmaCodimi == 0 then (
	    sigmaCodimi = {{}};
	);
        X.cache.Chow#i = ZZ^(#sigmaCodimi);
	return X.cache.Chow#i;   
     ) else tauCodimiminus1 := orbits(X,n-i+1);
     if i == 1 then (
	 tauCodimiminus1 = {{}};
     );
     if #tauCodimiminus1 > 0 then (
         --Create the relations (Fulton-Sturmfels eqtn 1, p337)
     Relns:=apply(tauCodimiminus1, tau -> (
     	  Mtau:= entries transpose gens kernel (matrix rays X)^tau;	  
	  TauRelns:=apply(Mtau, u->(
     	       reln:= apply(sigmaCodimi,sigma->(
     	       	    relnsigma:=0;
		    if isContained(tau,sigma) then (
     	       	    	  j:=position(sigma, k->(not(member(k,tau))));
			  nvect:=(rays X)#(sigma#j);
      	       	    	  udotn:=0;
		      	  for k from 0 to #u-1 do
			       udotn=udotn+(u#k)*(nvect#k);
 		          nsigmamult:=latticeIndex(append(tau,sigma#j) ,X) // latticeIndex(tau,X);
			  relnsigma=udotn // nsigmamult;
		    )
	       	    else (	 
		      relnsigma=0;
		    );
	       	    relnsigma
	       ));
	       reln
     	  ));
     	  TauRelns
     ));
     Relns=flatten Relns;
     X.cache.Chow#i = prune coker transpose matrix Relns;
     )
     else X.cache.Chow#i = ZZ^(#sigmaCodimi);
     );
     X.cache.Chow#i
);	 
	 

-- intersect (List, ZZ, List, NormalToricVariety) := List => (D, k, tau, X)  -> (
--      if isCartier(D) then (
--      n:=dim X;
--      Zorder := cones(n-k,X);
--      outputCones := cones(n-k+1, X);
--      --First rewrite D so that it is not supported on V(tau)
--      --????
--      --Then do the intersection 
--      DdotTau:=apply(outputCones, sigma -> (
--      	  if not(isContained(tau,sigma)) then 0
-- 	  else (
     	       	            	       	       
--      	  )
--      ));
--      return(DdotTau);
--      )
--      else (
-- 	  <<"D is not a Cartier divisor"<<endl;
-- --???should error trap properly
--      );
-- );     

--Intersect V(sigma) and V(tau) using the SR formulation.
--Not sure about the use of this.
-- intersect ( List, List, NormalToricVariety, ) := MutableHashTable =>( sigma, tau, X) -> (
--       if not isSimplicial X then error("Not implemented yet");
--       --We'll turn sigma into a product of torus-invariant divisors
--       --and do the intersection one-by-one
--       I:=SR(X);
--       R:=ring I;
--       m:=1_R;
--       for i in sigma do (
-- 	   m=m*R_i;
--       );
--       for i in tau do (
-- 	   m=m*R_i;
--       );
--       rem:= m % I;
--       rem   		   
-- );      


--Create SR ideal
iintersectionRing = method()

--matrix representing a map from ring we want to ring we get
iintersectionRing(NormalToricVariety,Ring,Matrix) := (X,S,M) -> (
    assert(numColumns M == rank chowGroup(1,X));
    assert(numRows M == #(rays X));
    inRing := iintersectionRing(X,S);
    z:=symbol z;
    R := S[z_0..z_(numColumns M - 1)];
    T := ring presentation inRing;
    L := for i from 0 to numColumns M - 1 list (
	sum (for j from 0 to numRows M - 1 list M_(j,i)*T_j)
	);
    phi := map(T, R, L);
    I := preimage(phi,ideal(inRing));
    R/I
);

iintersectionRing(NormalToricVariety,Matrix) := (X,M) -> (iintersectionRing(X,QQ,M));

iintersectionRing(NormalToricVariety,Ring) := (X,S) -> (
     if (not X.cache.?iintersectionRing) or (not coefficientRing(X.cache.iintersectionRing) === S) then (
 	 z:=symbol z;
       -- we construct a subtoricvariety, some ray indices won't appear
     	 -- R:=S[z_0..z_(#(rays X)-1)];
       rayIndices := orbits(X,dim X - 1) / first;
       R := S[rayIndices / (i -> z_i)];
       	 I:= ideal apply(max X, sigma->(
	       	    mono:=1_R;
	       	    for j in rayIndices do 
		        if not(member(j,sigma)) then mono=mono*z_j;
	       	    mono
		    ));
     	 squaresIdeal:=ideal apply(gens R, xx->xx^2);       
     	 I=ideal flatten entries ((gens (squaresIdeal : I)) % squaresIdeal);
       nonzeroRays := rayIndices / (i -> (rays X)#i);
     	 I=I+ ideal apply(transpose nonzeroRays, a->(
	       genJ:=0_R;
	       for j from 0 to #a-1 do (
		    genJ=genJ+a#j*R_j;
	       );
	       genJ    
     	 ));
     X.cache.iintersectionRing=R/(ideal mingens I);
     X.cache.AmbientRing = R;
     );
     X.cache.iintersectionRing
);
iintersectionRing(NormalToricVariety) := X -> (iintersectionRing(X,QQ));

--Compute a basis for the Chow ring
chowGroupBasis = method()
chowGroupBasis(NormalToricVariety,ZZ) := (X,i) -> (
     if not X.cache.?ChowGroupBas then
     	  X.cache.ChowGroupBas = new MutableHashTable;
     R:=iintersectionRing(X);
     if not X.cache.ChowGroupBas#?i then 	  
          X.cache.ChowGroupBas#i=flatten entries lift(basis(dim X -i,R),X.cache.AmbientRing);
     return(X.cache.ChowGroupBas#i);
);
chowGroupBasis(NormalToricVariety) := X -> (for i from 0 to dim X list chowGroupBasis(X,i))


--Code to compute the cone of nef cycles

--Currently returns a rather arbitrary  basis for the ith Chow group 
-- and then a matrix whose columns represent elements there
--generating the cone of nef i-cycles
--(Caveat: this is dimension i, so codimension n-i)

nefCone=(i,X)->(
     if not isSmooth(X) then error("Not implemented yet");
     n:=dim X;
     Conesi:=orbits(X,n-i);
     --Get intersection ring
     I:=ideal(iintersectionRing(X));
     R:=X.cache.AmbientRing;
     --Now create the multiplication map
     --First get a basis for chowGroup_i
     chowBas:=chowGroupBasis(X,i);
     mono:=1_R;
     for i in (max X)_0 do mono=mono*R_i;
     topBas1:=mono % I;
     Mat:=matrix unique apply(chowBas,m->(
	       apply(Conesi,sigma->(
			 mono:=1_R;
			 for j in sigma do mono=mono*R_j;
     	       	    	 --Assumes R has coefficients in QQ
     	       	    	 lift(((m*mono) % I)/topBas1, QQ)
     	       ))
     ));
--Temporarily assuming that cone is full-dimensional - is it always???
--<<"Got this far with nefCone"<<endl;
--<<rank source Mat <<"    "<<rank target Mat <<endl;
    matDual:=-1*(fourierMotzkin Mat)#0;
    return(matDual);
);


--Compute the effective cone of i cycles in X
-- i is the dimension?
effCone=(i,X)->(
     if not isSmooth(X) then error("Not implemented yet");     
     n:=dim X;
     --Get intersection ring
     I:=ideal(iintersectionRing(X));
     R:=X.cache.AmbientRing;
     if not X.cache.?ChowGroupBas then
     	  X.cache.ChowGroupBas = new MutableHashTable;
     if not X.cache.ChowGroupBas#?i then 	  
          X.cache.ChowGroupBas#i=flatten entries lift(basis(n-i,R/I),R);
     --j=n-i
     Conesj:=orbits(X,i);
     EffMat:=transpose matrix apply(Conesj,sigma->(
    	  mono:=1_R;
	  for j in sigma do mono=mono*R_j;
     	  mono=mono % I;
	  apply(X.cache.ChowGroupBas#i,m->(coefficient(m,mono)))
     ));	  
     return(EffMat);
);


     
ToricCycle = new Type of HashTable
ToricCycle.synonym = "toric cycle"
debug Core --- kludge to access "hasAttribute" and getAttribute

expression ToricCycle := Expression => C -> (
   X := variety C;
    divisorSymbol := if hasAttribute(X,ReverseDictionary) then 
    	expression toString getAttribute(X,ReverseDictionary) 
	else expression "v";
    -- S := apply(C, p -> first p);
    S := support C;
    if S === {} then return expression 0;
    Sum apply(S, j -> (
	    coeff := expression abs(C#j);
	    if C#j === -1 then 
	        Minus Subscript{divisorSymbol, j}
	    else if C#j < 0 then 
	        Minus {coeff * Subscript{divisorSymbol, j}}
	    else if C#j === 1 then 
	        Subscript{divisorSymbol, j}
	    else coeff * Subscript{divisorSymbol, j} )));  

net ToricCycle := C -> net expression C
ToricCycle#{Standard,AfterPrint} = 
ToricCycle#{Standard,AfterNoPrint} = C -> (
    << endl;				  -- double space
    << concatenate(interpreterDepth:"o") << lineNumber << " : ToricCycle on ";
    << variety C << endl;);
    
variety ToricCycle := C -> C.variety

support ToricCycle := C -> (
    cones := flatten values orbits(variety C);
    select(cones, c -> C#c =!= 0)
)
  
toricCycle = method(TypicalValue => ToricCycle)
toricCycle (List, NormalToricVariety) := (conesWithMultiplicities, X) -> (
    toArrow := (i,j) -> (i => j);
    cones := flatten values orbits X;
    conesWithMultiplicities = for tuple in conesWithMultiplicities list (sort(tuple#0),tuple#1);
    zerocones := select(cones, c -> not member(c,conesWithMultiplicities / first));
    new ToricCycle from apply(conesWithMultiplicities, p -> toArrow(p)) | apply(zerocones, p->p=>0) | {
        symbol variety => X
    }
)


ZZ * ToricCycle := ToricCycle => (k,C) -> (
    V := for orbit in flatten values orbits variety C list (orbit,k*(C#orbit));
    toricCycle(V,variety C)
);

ToricCycle + ToricCycle := ToricCycle => (C,D) -> (
    assert(variety C === variety D);
    V := for orbit in flatten values orbits variety C list (orbit, (C#orbit)+(D#orbit));
    toricCycle(V, variety C)
);

ToricCycle - ToricCycle := ToricCycle => (C,D) -> (
    C + (-1)*D
);

- ToricCycle := ToricCycle => (C) -> (-1)*C


--toricDivisor = method()
toricDivisor(Vector,NormalToricVariety) := opts -> (u,X) -> (
    -- u is a vector in M
    -- returns the divisor of zeros and poles of chi^u
    --cs := for r in rays X list (
    --    u * vector(r)    
    --); 
    --sum apply(cs,0..(#(rays X) - 1), (c,i) -> c*X_i)    
    sum (#(rays X), i -> (u * vector((rays X)_i))*X_i)
)

Vector * Vector := (a,b) -> (
    first entries ((matrix {entries a}) * b )
)


ToricDivisor * List := (D, C) -> (
    -- D is a divisor on X
    -- C is a cone in the fan of X
    assert(isCartier(D));
    X := variety D;
    if not isTransverse(D,C) then (
        -- u := vector(random(ZZ^(#(first rays variety D)),ZZ^1));
        d := # rays X;
        l := C | toList (set(0..(d-1)) - C);  -- reorder ray indices to put C first
        Ds := l / (i -> X_i);  -- reorder divisors
        m := transpose matrix ( l / (i -> (rays X)#i) );  -- reorder rays
        M := inverse(m_{0..numRows m-1}) * m;  -- gaussian elim
        eqs := for r in entries M list (
            sum (apply(r,Ds, (e,Di) -> e*Di))
        );
        for i from 0 to # eqs - 1 do (
            D = D - (entries D)#(l#i) * (eqs#i)
        );
    );
    local i;
    for k in keys(orbits X) do (
        if member(C,orbits(X,k)) then i = k
    );
    dimiplus1cones := if i > 0 then (orbits X)#(i-1) else return 0*((variety D)_{});
    V := for r from 0 to #rays(X)-1 list (
        if member(sort(C|{r}),dimiplus1cones) then
            (sort(C|{r}),D#r)
        else
            continue
    );
    toricCycle(V,X)
)

NormalToricVariety _ List := (X,L) -> (toricCycle({(L,1)},X))

-- Need to be careful when cycle class is supported on a point
-- Output is the point normalToricVariet({{}},{{}}). The NormalToricVarieties 
-- package doesn't treat this as a Toric variety.
normalToricVariety(ToricCycle) := opts -> C -> (
    s := support C;
    if #s > 1 then error "Expected a cycle of a cone";
    normalToricVariety(first s, variety C)
)


normalToricVariety(List,NormalToricVariety) := opts -> (r,X) -> (
    if any(r, e -> class e === List) then error "Expected a list of rays"; 
    -- get cones containing r
    newOrbits := for o in (orbits X)#0 list (
        if isSubset(set(r),set(o)) then o else continue
    );
    -- r goes to 0, so remove the indices from r
    newOrbits = unique for o in newOrbits list (toList(set(o) - r));
    -- if the the variety is a point
    
    -- quotient out <r> and remove 0s
    M'  := transpose matrix rays X;
    M'' := transpose (M' % (M'_r));
    z' := map(ZZ^1,ZZ^(numcols M''),0);
    listZero := select(numrows M'', v-> not M''^{v} == z');
    M := M''^listZero;
    
    z := map(ZZ^(numRows M),ZZ^1,0);  -- zero matrix of correct size
    cols := for i from 0 to numColumns M - 1 list ((M)_{i});
    M = fold(for i in cols list (if i == z then continue else i),(i,j) -> i|j);
    Y := normalToricVariety(entries M,newOrbits);
    Y.cache.parent = X;
    return Y
   
--- Old code
--    M' := transpose matrix rays X;
--    M := transpose (M' % (M'_r)); -- quotient out <r>

--    z := map(ZZ^(numRows M),ZZ^1,0);  -- zero matrix of correct size
--    cols := for i from 0 to numColumns M - 1 list ((M)_{i});
--    M = fold(for i in cols list (if i == z then continue else i),(i,j) -> i|j);
--    Y := normalToricVariety(entries M,newOrbits);
--    Y.cache.parent = X;
--    return Y       
) 
    
toricCycle(ToricDivisor) := D -> (
    X := variety D;
    coeffs := entries D;
    sum for i when i < #coeffs list (coeffs#i * X_{i})
)

ToricDivisor * ToricDivisor := (D,E) -> (
    D * toricCycle E
)

ToricDivisor * ToricCycle := (D,C) -> (
    sum for c in support C list (
        C#c * ( D * c )
    )
)


ToricCycle == ToricCycle := Boolean => (D,E) -> (
    return variety D === variety E and (for orbit in flatten values orbits variety D list D#orbit)==(for orbit in flatten values orbits variety E list E#orbit); 
);


isTransverse = method()

isTransverse(ToricDivisor, List) := (D,E) -> (
    nonzeroRaysofD := for i from 0 to (#(rays variety D) - 1) list (if D#i == 0 then continue; i);
    #(set(nonzeroRaysofD)*set(E)) == 0
);

isTransverse(List,List) := (D,E) -> (
    not isSubset(D,E) and not isSubset(E,D)
);


---------------------------------------------------------------------------
-- DOCUMENTATION
---------------------------------------------------------------------------
beginDocumentation()

undocumented {(net,ToricCycle),(expression,ToricCycle)}

doc ///
    Key
        Chow
    Headline
        intersection theory for normal toric varieties
    Description
        Text
            This is a subpackage for eventual inclusion into Greg Smith's NormalToricVarieties package
        Text 
            It contains routines to do compute the Chow ring and groups of a normal toric variety, plus compute the nef and effective cones of cycles.
///


doc ///
  Key
      chowGroup
  Headline
      Chow rings for toric varieties
  Usage
      chowGroup(i,X)
  Inputs
      i:ZZ
      X:NormalToricVariety
  Outputs
      :Module
         the codim-i Chow group $A^i(X)$, an abelian group (a  ZZ-module)
  Description
      Text
         This procedure computes the ith Chow group of the NormalToricVariety X. It produces it as the cokernel of a matrix, 
	 following the description given in Proposition 2.1 of Fulton-Sturmfels
	 Intersection Theory on toric varieties (Topology, 1996). 
      Text
         It is cached in X.cache.Chow#i.
--      Text 
--         ???say something about pruning map.
      Text 
         These groups are all one-dimensional for projective space.  
      Example 
         X = toricProjectiveSpace 4
	 rank chowGroup(1,X) 
	 rank chowGroup(2,X) 
	 rank chowGroup(3,X)
      Text
         We next consider the blow-up of P^3 at two points.
      Example
         X=normalToricVariety({{1,0,0},{0,1,0},{0,0,1},{-1,-1,-1},{1,1,1}, {-1,0,0}}, {{0,2,4},{0,1,4},{1,2,4},{1,2,5},{2,3,5},{1,3,5},{0,1,3},{0,2,3}})
         chowGroup(1,X) 
         chowGroup(2,X)
/// 	 

doc ///
    Key
        chowGroupBasis
        (chowGroupBasis,NormalToricVariety)
        (chowGroupBasis,NormalToricVariety,ZZ)
    Headline
        the basis of the Chow group in dim i
    Usage
        chowGroupBasis(X) or chowGroupBasis(X,i)
    Inputs
        X:NormalToricVariety
	i:ZZ
    Outputs
        :Module
	   a basis for the ith Chow group (a ZZ-module)
    Description
       Text 
         This method returns the cached basis for the Chow group of dimension-i cycles on X.  
	 If called without i, it returns a list so that chowGroupBasis(X)#i = chowGroupBasis(X,i).
       Example
         X = toricProjectiveSpace 4 
         chowGroupBasis(X)
       Example
         X=normalToricVariety({{1,0,0},{0,1,0},{0,0,1},{-1,-1,-1},{1,1,1}, {-1,0,0}}, {{0,2,4},{0,1,4},{1,2,4},{1,2,5},{2,3,5},{1,3,5},{0,1,3},{0,2,3}})
         chowGroupBasis(X)
         chowGroupBasis(X,2) -- a basis for divisors on this threefold
///


doc ///
     Key
       effCone
     Headline
       the cone of effective T-invariant i-cycles  
     Usage
       effCone(i,X)
     Inputs
       i:ZZ
       X:NormalToricVariety
     Outputs
       :Matrix
         whose columns are the generators for the cone of effective i-cycles
     Description
       Text
         This is currently only implemented for smooth toric varieties.
         The columns should be given in a basis for the i-th Chow group
         recorded in X.cache.ChowGroupBas#i and accessed via chowGroupBasis(X).
       Example
         X = toricProjectiveSpace 4
         effCone(2,X)
       Example 
         X = hirzebruchSurface 1;
         effCone(1,X)
/// 


doc ///
     Key
       isTransverse
       (isTransverse, ToricDivisor, List)
       (isTransverse, List, List)
     Headline
       checks transversality of toric divisors and cones
     Usage
       isTransverse(D,E)
       isTransverse(E,F)
     Inputs
       D:ToricDivisor
       E:List
       F:List
     Outputs
       :Boolean
     Description
       Text
         This function tests transversality of toric divisors and cones. Toric
	 divisors are represented using the ToricDivisor class and cones are represented
	 using lists.
       Example
         rayList={{1,0},{0,1},{-1,-1},{0,-1}}
	 coneList={{0,1},{1,2},{2,3},{3,0}}
	 X = normalToricVariety(rayList,coneList)
	 D = X_3
	 E = {0,3}
	 F = {1,2}
	 isTransverse(D,E)
	 isTransverse(D,F)
       Text
         We can also check whether the two cones are transverse.
       Example
         isTransverse(F,F)
         isTransverse(E,F)     
///  


doc ///
     Key
       nefCone
     Headline
       the cone of nef T-invariant i-cycles   
     Usage
       nefCone(i,X)
     Inputs
       i:ZZ
       X:NormalToricVariety
     Outputs
       :Matrix
         whose columns are the generators for the cone of nef i-cycles
     Description
       Text
         A cycle is nef if it intersects every effective cycle of
         complementary dimension nonnegatively.
	 This is currently only implemented for smooth toric varieties.
	 The columns are given in a basis for the i-th Chow group
         recorded in X.cache.ChowGroupBas#i and accessed via chowGroupBasis(X).
       Example
         X=toricProjectiveSpace 4
         nefCone(2,X)
       Example 
         X=hirzebruchSurface 1;
	 nefCone(1,X)
///        

doc ///
    Key
        ToricCycle
    Headline
        the class of a toric cycle on a NormalToricVariety
    Description
        Text
          A toric cycle on X is a finite formal sum of closed torus orbits corresponding to cones in the fan of X.
	Text
	  Examples can be found on the toricCycle constructor page.
    SeeAlso
        toricCycle
///

doc ///
    Key
        toricCycle
        (toricCycle,List,NormalToricVariety)
    Headline
        Creates a ToricCycle
    Usage
        toricCycle(L,X)
    Inputs
        L:List
            a list of tuples (sigma,d) where d is the multiplicity of the cone sigma
        X:NormalToricVariety
            the variety the cycle lives on
    Outputs
        :ToricCycle
    Description
        Text
	  Toric cycles can be created with the constructor, and as they form an abelian group under addition,
	  arithmetic can be done with them.
	Example
	  rayList={{1,0},{0,1},{-1,-1},{0,-1}}
	  coneList={{0,1},{1,2},{2,3},{3,0}}
	  X = normalToricVariety(rayList,coneList)
	  cyc = toricCycle({({2,3},1),({3,0}, 4)},X)
	  altcyc = (-2)*cyc
	  cyc + altcyc
	  cyc - altcyc
	  -cyc
    SeeAlso
      (symbol +, ToricCycle, ToricCycle)
///


doc ///
    Key
        (support,ToricCycle)
    Headline
        Get the list of cones with non-zero coefficients in the cycle
    Usage
        support C
    Inputs
        C:ToricCycle
    Outputs
        :List
            a list of integer vectors describing cones in the
	    fan of variety(C)
    Description
        Text
	    This function returns the list of cones, corresponding 
	    to torus-invariant cycles, appearing in the support of
	    a ToricCycle.
	Example
	    X = toricProjectiveSpace 4
	    Z1 = toricCycle({({0,1},3),({0,2},7),({1,2},82)},X)
	    Z2 = toricCycle({({0,1},4),({0,2},5)},X)
	    support Z1
	    support Z2
///

doc ///
    Key
        (variety,ToricCycle)
    Headline
        Get the ambient variety of the cycle
    Usage
        variety C
    Inputs
        C:ToricCycle
    Outputs
        :NormalToricVariety
    Description
        Text
	    This function returns the underlying toric variety of
	    the toric cycle.
	Example
	    X = toricProjectiveSpace 2
	    Z = toricCycle({({0,1},3),({0,2},7),({1,2},82)},X)
	    variety Z	    
///
     
-- doc ///
--     Key
--     Headline
--     Usage
--     Inputs
--     Outputs
--     Description
--         Text
--         Example
-- ///
     
     
doc ///
     Key
       iintersectionRing
       (iintersectionRing,NormalToricVariety)
       (iintersectionRing,NormalToricVariety,Ring)
       (iintersectionRing,NormalToricVariety,Ring,Matrix)
       (iintersectionRing,NormalToricVariety,Matrix)
     Headline
       compute the Chow ring of a smooth toric variety
     Usage
       iintersectionRing(X)
       iintersectionRing(X,S)
       iintersectionRing(X,S,M)
       iintersectionRing(X,M)
     Inputs 
       X:NormalToricVariety
       S:Ring
         a coefficient ring for the intersection ring returned
       M:Matrix
         must be a n by m matrix, where n is the number of rays of X, and m
	 is the rank of the codimension 1 Chow group.
     Outputs
       :Ring
         the intersection ring of X
     Description
       Text 
         By default, the ring will have coefficients in QQ and will have one variable 
	 for each ray of X. The ring returned is a polynomial ring modulo an ideal. 
	 The ideal is the ideal given in the Stanley-Reisner presentation of
         the cohomology ring of X.
       Text
         This assumes that X is smooth.  Eventually it will be
         implemented for simplicial toric varieties.
       Example
         X = toricProjectiveSpace 2
         R = iintersectionRing X
         for i from 0 to 2 do <<hilbertFunction(i,R)<<endl
       Text 
         Next we consider the blow-up of P^3 at 2 points.
       Example 
         X=normalToricVariety({{1,0,0},{0,1,0},{0,0,1},{-1,-1,-1},{1,1,1}, {-1,0,0}}, {{0,2,4},{0,1,4},{1,2,4},{1,2,5},{2,3,5},{1,3,5},{0,1,3},{0,2,3}})
	 R = iintersectionRing X
         hilbertFunction(1,R)
       Text 
         Note that the degree-one part of the ring has dimension the Picard-rank, as expected.
       Text
         Note that a coefficient ring can also be specified by inputting a parameter S. 
	 By default, the coefficient ring is the rational numbers.
       Example
         X = toricProjectiveSpace 2
	 R = iintersectionRing(X,ZZ)
	 for i from 0 to 2 do <<hilbertFunction(i,R)<<endl
       Text
         A nicer presentation of X can be returned by making use of the parameter M. Consider the
	 blowup of PP2 at a point. Let H be the divisor class of a line, and let E be the 
	 exceptional divisor. H and E generate the intersection ring, but the standard presentation
	 is not minimal in the sense that it returns extranous variables.
       Example
         rayList={{1,0},{0,1},{-1,-1},{0,-1}}
	 coneList={{0,1},{1,2},{2,3},{3,0}}
	 X = normalToricVariety(rayList,coneList)
	 rank chowGroup(1,X)
       Text
         The rank of the codimension 1 subgroup tells us the minimal number of generators.
	 We know that E corresponds to the ray {0,-1} and H corresponds to the ray {0,1}. 
	 We can obtain a presentation of the intersection ring in two variables H and E as follows.
       Example
         M = matrix{{0,0},{0,1},{0,0},{1,0}}
	 iintersectionRing(X,QQ,M)
       Text
         Here, E corresponds to z_0 and H corresponds to z_1.
///

doc ///
     Key
        isContainedCones
     Headline
        decide if one cone is contained inside another
     Usage
        isContainedCones(M,N)
     Inputs
        M:Matrix
	N:Matrix
     Outputs
       :Boolean
          Returns true if the cone generated by the columns of the matrix
     Description
        Text
          M is contained in the cone generated by the columns of the matrix N.
          This currently assumes that both cones are full-dimensional, and is implemented in 
          a somewhat hackish manner.
///

doc ///
    Key
      (symbol *, ToricDivisor, List)
    Headline
      restriction of a Cartier toric divisor to the orbit closure of a cone
    Usage
      D*C
    Inputs
      D:ToricDivisor
      C:List
    Outputs
      :ToricCycle
         Returns the toric cycle given by restricting a Cartier toric divisor to the
	 orbit closure of the given cone
    Description
      Example
        rayList={{1,0},{0,1},{-1,-1},{0,-1}}
	coneList={{0,1},{1,2},{2,3},{3,0}}
	X = normalToricVariety(rayList,coneList)
	D = X_3
      Text
        The only cone containing rays 2 and 3 is the cone {2,3}. There is no cone
	containing rows 1 and 3.
      Example
        D*{2}
        D*{1}
      Text
        This can also compute more complicated sums.
      Example
        D = X_0 + 2*X_1+3*X_2+4*X_3
	C = (orbits X)#1#0
	D*C
///

doc ///
    Key
      (symbol == , ToricCycle, ToricCycle)
    Headline
      equality of toric cycles
    Usage
      C == D
    Inputs
      C:ToricCycle
      D:ToricCycle
    Description
      Text
        In order for this method to work, the varieties C and D are on must be the same object. Given this, 
	this function checks that the coefficient of each orbit of the toric varieties in both toric cycles
	are the same.
      Example
        rayList={{1,0},{0,1},{-1,-1},{0,-1}}
	coneList={{0,1},{1,2},{2,3},{3,0}}
	X = normalToricVariety(rayList,coneList)
	D = X_3
	D*{2} == toricCycle({({2,3},1)},X)
	D*{1} == toricCycle({},X)
      Text
        The elements of the list in the constructor of toric cycle may be in any order. For example,
	the following example has {3,0} instead of {0,3}.
      Example
	D*{0} == toricCycle({({3,0},1)},X)
    SeeAlso
      (symbol *, ToricDivisor, List)
///

doc ///
    Key
      (symbol *, ToricDivisor, ToricCycle)
    Headline
      multiplication of a ToricDivisor and ToricCycle 
    Usage
      D*C
    Inputs
      D:ToricDivisor
      C:ToricCycle
    Description
      Text
        Computes the product of a ToricDivisor with a ToricCycle.
      Example
	X = toricProjectiveSpace 4
	D = X_0 + 2*X_1+3*X_2+4*X_3
	C = X_{2,3}
	D*C   
      Text
      	Self intersection of the exceptional divisor.
      Example
	X = toricProjectiveSpace 2
	Y = toricBlowup({0,1},X)
	D = Y_3
	C = Y_{3}
	D*C       	
/// 

doc ///
    Key
      (symbol +, ToricCycle, ToricCycle)
      (symbol -, ToricCycle, ToricCycle)
      (symbol -, ToricCycle)
      (symbol *, ZZ, ToricCycle)
    Headline
      perform arithmetic on toric cycles
    Usage
      C1 + C2
      C1 - C2
      5*C1
      -C1
    Inputs
      C1:ToricCycle
      C2:ToricCycle
    Description
      Text
        The set of torus-invariant Weil divisors forms an abelian group
	under addition.  The basic operations arising from this structure,
	including addition, substraction, negation, and scalar
	multplication by integers, are available.
      Text
	We illustrate a few of the possibilities on one variety.
      Example
        rayList={{1,0},{0,1},{-1,-1},{0,-1}}
        coneList={{0,1},{1,2},{2,3},{3,0}}
        X = normalToricVariety(rayList,coneList)
	cyc = toricCycle({({2,3},1),({3,0}, 4)},X)
	altcyc = (-2)*cyc
	cyc + altcyc
	cyc - altcyc
	-cyc
///
doc ///
    Key
        (normalToricVariety, ToricCycle)
    Headline
        the toric variety corresponding to an irreducible cycle.
    Usage
        normalToricVariety Z
    Inputs
        Z:ToricCycle
    Outputs
        X:NormalToricVariety
    Description
        Text
            Given an irreducible ToricCycle Z, supported on only
            one cone, this function returns
	    the toric variety of the corresponding orbit closure.
	Example
	    X = toricProjectiveSpace 4
	    Z = 4*X_{0,1}
	    Y = normalToricVariety Z
	    dim Y
	    rays Y
///

doc ///
    Key
        (toricDivisor, Vector, NormalToricVariety)
    Headline
        creates the principal divisor corresponding to the torus-invariant function
    Usage
        toricDivisor(u,X)
    Inputs
        u:Vector
	X:NormalToricVariety
    Outputs
        Z:ToricDivisor
    Description
        Text
	    Given a vector u in M, the function returns the divisor
	    of the torus-invariant function chi^u.
	Example
	    X = affineSpace 2
	    u = vector({29,73})
	    Z = toricDivisor(u,X)	
///


---------------------------------------------------------------------------
-- TEST
---------------------------------------------------------------------------

--TODO

--Need to add some non-smooth and noncomplete ones
--Check iintersectionRing and chowGroup give the same answer (at least numerically)
-- for the databases (smooth Fanos, and smallAmpleToricDivisor)
--Affine space
--check for smooth that ToricDivisor * ToricCycle agrees with iintersectionRing 

--Replace X by something more interesting
TEST ///
X=toricProjectiveSpace 4
assert(rank chowGroup(3,X) == rank chowGroup(1,X))
assert(rank chowGroup(3,X) == rank picardGroup X)
R = iintersectionRing X
S = QQ[x]/ideal(x^5)
phi = map(S,R,{x,x,x,x,x})
psi = map(R,S,{R_0})
assert(matrix inverse psi == matrix phi)
/// 

TEST ///
A=sort apply(3,i->random(5))
X=kleinschmidt(6,A)
R=QQ[x,y]
I=ideal(x^4,y^4)
for i from 0 to 6 do
     assert(rank chowGroup(i,X) == hilbertFunction(i,R/I))
///

--do P2 blown up at a point QQ[H,E]/(H^3, E^2 + H^2, E^3)
TEST ///
rayList={{1,0},{0,1},{-1,-1},{0,-1}}
coneList={{0,1},{1,2},{2,3},{3,0}}
X = normalToricVariety(rayList,coneList)
assert(rank chowGroup(0,X) == 1)
assert(rank chowGroup(1,X) == 2)
assert(rank chowGroup(2,X) == 1)
R = iintersectionRing X
S = QQ[E,H]/(H^3,E^2+H^2,E^3)
phi = map(S,R,{H-E,H,H-E,E})
psi = map(R,S,{R_3,R_1})
assert(matrix inverse psi == matrix phi)

D = X_3
-- ToricDivisor * List
assert(D*{3} == - toricCycle({({2,3},1)},X))
assert(D*{2} == toricCycle({({2,3},1)},X))
assert(D*{1} == toricCycle({},X))
-- test reverse order
assert(D*{0} == toricCycle({({3,0},1)},X))
-- ToricDivisor * ToricCycle
assert(D*X_{3} == - toricCycle({({2,3},1)},X))
assert(D*(X_{2}+X_{3}) == toricCycle({},X))


--check isTransverse
E = {0,3}
F = {1,2}
assert(not isTransverse(F,F))
assert(isTransverse(E,F))
assert(not isTransverse(D,E))
assert(isTransverse(D,F))

///


--do P1xP1 -> P3 QQ[H,K]/(H^2, K^2)
TEST ///
rayList={{1,0},{0,1},{-1,0},{0,-1}}
coneList={{0,1},{1,2},{2,3},{3,0}}
X = normalToricVariety(rayList,coneList)
assert(rank chowGroup(1,X) == 2)
assert(rank chowGroup(2,X) == 1)
assert(rank chowGroup(0,X) == 1)
R = iintersectionRing X
S = QQ[H,K]/(H^2,K^2)
phi = map(S,R,{H,K,H,K})
psi = map(R,S,{R_0,R_1})
assert(matrix inverse psi == matrix phi)
///

--test ToricCycle addition, subtraction, multiplication, etc
TEST ///
rayList={{1,0},{0,1},{-1,-1},{0,-1}}
coneList={{0,1},{1,2},{2,3},{3,0}}
X = normalToricVariety(rayList,coneList)

cyc = toricCycle({({2,3},1),({3,0}, 4)},X)
altcyc = (-2)*cyc
assert(altcyc == toricCycle({({2,3},-2),({3,0}, -8)},X))
assert(cyc + altcyc == ((-1)*cyc))
assert(cyc - altcyc == 3*cyc)
assert(-cyc == (-1)*cyc)
///

end

---------------------------------------------------------------------------
-- SCRATCH SPACE
---------------------------------------------------------------------------
 
restart
loadPackage "Chow"
--X is blow-up of P^3 at two points
raysX={{1,0,0},{0,1,0},{0,0,1},{-1,-1,-1},{1,1,1}, {-1,0,0}};
Sigma={{0,2,4},{0,1,4},{1,2,4},{1,2,5},{2,3,5},{1,3,5},{0,1,3},{0,2,3}};
X=normalToricVariety(raysX,Sigma);

--X is the blow-up of P^4 at 2 points

raysX={{1,0,0,0},{0,1,0,0},{0,0,1,0},{0,0,0,1},{-1,-1,-1,-1},{1,1,1,1},{-1,0,0,0}};
Sigma={{0,1,2,4},{0,1,3,4}, {0,2,3,4}, {0,1,2,5}, {0,1,3,5},
{0,2,3,5}, {1,2,3,5}, {1,2,3,6}, {1,2,4,6}, {1,3,4,6}, {2,3,4,6}};
X=normalToricVariety(raysX,Sigma);

--Y is the blow-up of P^4 at 1 point
raysY={{1,0,0,0},{0,1,0,0},{0,0,1,0},{0,0,0,1},{-1,-1,-1,-1},{1,1,1,1}};
Sigma2 = {{0,1,2,4}, {0,1,3,4}, {0,2,3,4}, {1,2,3,4}, {0,1,2,5}, {0,1,3,5},
     {0,2,3,5}, {1,2,3,5}};
Y=normalToricVariety(raysY,Sigma2);

-- document { 
--      Key => {(cones, (ZZ, NormalToricVariety)},
--      Headline => "the i dimension cones of the fan",
--      Usage => "cones(i,X)"
--      Inputs => {
-- 	  "i" => "a nonnegative integer",
-- 	  "X" => NormalToricVariety
-- 	  },
--      Outputs => {},

--      EXAMPLE lines ///
-- 	  PP1 = toricProjectiveSpace 1;
-- 	  ///,
--      SeeAlso => {normalToricVariety, weightedProjectiveSpace,
-- 	  (ring,NormalToricVariety), (ideal,NormalToricVariety)}
--      }     


--stellarSubdivision bug/features
----doesn't add new ray at end
----when adding ray that is already there it doesn't realize it
----Also creates X.cache.cones (name clash)

--For example - try blow-up of P4 at 2 points



W=sort apply(5,i->random(7)+1);
while not all(subsets(W,4), s -> gcd s === 1) do 
      W=sort apply(5,i->random(7)+1);
X=resolveSingularities weightedProjectiveSpace(W);
summ=0;
R = iintersectionRing(X);
I = ideal(R);
scan(5,i->(summ=summ+(hilbertFunction(i,R/I)-rank(chowGroup(i,X)))^2;));
<<summ<<endl;


uninstallPackage "Chow"
uninstallPackage "NormalToricVarieties"
restart
loadPackage "Chow"
needsPackage "Chow"
installPackage "NormalToricVarieties"
installPackage "Chow"
check "Chow"

viewHelp Chow

X = toricProjectiveSpace 4
D = X_1
u = vector({1,2,3,4})
Z = toricDivisor(u,X)
D' = D + Z

X = affineSpace 2
u = vector({29,73})
Z = toricDivisor(u,X)

rayList={{1,0},{0,1},{-1,-1},{0,-1}}
coneList={{0,1},{1,2},{2,3},{3,0}}
X = normalToricVariety(rayList,coneList)
D = X_0 + 2*X_1+3*X_2+4*X_3
C = (orbits X)#1#0
D*C
E = X_3
E * {3}
E * (X_{3})

u = vector({-3,2})
cs = for r in rays X list (
    u * vector(r)    
    )
sum apply(cs,0..(#(rays X) - 1), (c,i) -> c*X_i)

-- X = toricProjectiveSpace 4
D = X_0 + 2*X_1 - 7*X_3
assert(isCartier(D))
orbits(X)
n = 2
i = 1
C = (orbits X)#i#0
raysC = C / (t -> (rays X)#t)
dimiplus1cones = (orbits X)#(i-1)
gammas = for sigma in dimiplus1cones list (
    if isSubset(C,sigma) then sigma else continue
)
for g in gammas do (
    Igamma = g - set(C);
    print Igamma
)        

uninstallPackage "Chow"
restart
installPackage("Chow",RemakeAllDocumentation=>false,RunExamples=>false,RerunExamples=>false)
installPackage "Chow"
check "Chow"

X = toricProjectiveSpace 4
E = X_2
D = X_2 + 3*X_3 - 7*X_4
E * D
toricCycle D
Y = normalToricVariety(support E, X)
iintersectionRing Y

normalToricVariety((orbits X)#2#1,X)
