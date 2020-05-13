export{"geneig"}

geneig = method()
geneig(Ring) := kk -> (
    x := symbol x;
    R := kk[x_1..x_6];
   { -10*x_1*x_6^2+ 2*x_2*x_6^2-x_3*x_6^2+x_4*x_6^2+ 3*x_5*x_6^2+x_1*x_6+ 2*x_2*x_6+x_3*x_6+ 2*x_4*
       x_6+x_5*x_6+ 10*x_1+ 2*x_2-x_3+ 2*x_4-2*x_5,
       2*x_1*x_6^2-11*x_2*x_6^2+ 2*x_3*x_6^2-2*x_4*x_6^2+x_5*x_6^2+ 2*x_1*x_6+x_2*x_6+ 2*x_3*x_6+x_4*
       x_6+ 3*x_5*x_6+ 2*x_1+ 9*x_2+ 3*x_3-x_4-2*x_5,
       -x_1*x_6^2+ 2*x_2*x_6^2-12*x_3*x_6^2-x_4*x_6^2+x_5*x_6^2+x_1*x_6+ 2*x_2*x_6-2*x_4*x_6-2*x_5*x_6-
       x_1+ 3*x_2+ 10*x_3+ 2*x_4-x_5,
       x_1*x_6^2-2*x_2*x_6^2-x_3*x_6^2-10*x_4*x_6^2+ 2*x_5*x_6^2+ 2*x_1*x_6+x_2*x_6-2*x_3*x_6+ 2*x_4*
       x_6+ 3*x_5*x_6+ 2*x_1-x_2+ 2*x_3+ 12*x_4+x_5,
       3*x_1*x_6^2+x_2*x_6^2+x_3*x_6^2+ 2*x_4*x_6^2-11*x_5*x_6^2+x_1*x_6+ 3*x_2*x_6-2*x_3*x_6+ 3*x_4*
       x_6+ 3*x_5*x_6-2*x_1-2*x_2-x_3+x_4+ 10*x_5,
       x_1+x_2+x_3+x_4+x_5-1 }
						
 )

  
  beginDocumentation()

doc /// 
    Key
    	geneig
	(geneig,Ring)
    Headline
    	generalized eigenvalue problem 
    Usage
    	geneig(kk)
    Inputs
    	kk:Ring
    Outputs
    	:List 	  of solutions
    Description
    	Text
	    The Bezout bound is 243 and the actual root count is 10. 
	    
	    Reference: "Homotopy method for general lambda-matrix problems" by M. Chu, T.Y. Li and
	     T. Sauer (pages 528-536).
	     
	    See also: http://homepages.math.uic.edu/~jan/Demo/geneig.html.
	Example
	     F = geneig(QQ)
  	     time sols = solveSystem F;
  	     #sols
    ///