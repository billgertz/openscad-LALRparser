openscad-LALRparser
===================
Description
===========
This implements a LALR parser that parses (x,y) coordinate list or list of 
shapes for use with Thingiverse's Customizer) into OpenSCAD Vector. Initially
intended to specify holes or pins for circuit board mount point, or a list of
shapes to cut out of a panel. This parser allows free form input rather than
using an ugly and clumsy exhaustive field driven interface.

X,Y Coordinate Specification
============================
List of coordinates in the form: (*x*, *y*) 
     
List can be specifed white space insensitive using any combination of 
coordinate delimiters of *none*, "," or ";"
     
For example:
* (12.1, -13.32), ( 5, -27),(.30,-1.0)
* (3,2),(84.3,-2 ) , ( 11 , 1. 02)(12,12)
* ( 1 4, 2 7 . 0 5);(-  28.1,4) ;(-0 ,-.1  )
 
The engine tolerates wild spacing around numbers, and even odd number
specifications, e.g. -0.0. However malformed lists and/or coordinates
are discarded. e.g. "(1-1,0)" "(1.0.0,7)" "(.,.3)" "(1,2)(1" "()"

Shape Specification
===================
List of shapes (circle, rectangle or square) as follows:
* cir(*diameter*) @ (*x-center*, *y-center*)
* rec(*width*, *height*) @ (*x-center*, *y-center*)
* sqr(*side*) @ (*x-center*, *y-center*)
     
As with coordinates, list can be specifed white space insensitive using
any combination of coordinate delimiters of <none>, "," or ";"
     
For example:
* cir(5)@(12.1, -13.32) rec( 5, -27) @ (.30,-1.0)
* rec (3,2) @(84.3,-2 ) , sqr( 11 ) @ ( - 2, 1. 02)
* rec( 1 4, 2 7 . 0 5)@(-  28.1,4) ;cir(34)@(-0 ,-.1  )
 
The engine tolerates wild spacing around numbers, and even odd number
specifications, e.g. -0.0. However malformed lists and/or shapes are 
discarded. e.g. "cir(1-1)@(1,1)" "sqr(1,1)*(1.0.1,6)" "rec(.,.3)@(1,1)"

Notes
=====
This can be used as skeleton for different language parsers, but you
need to hand edit not only the token, grammar and fsa tables but embed
a bespoke *_reduce* function.

Unfortunaely the _reduce function must be declared for each LALR parser
The _parser could be specified as a function when OpenSCAD v2.0 is 
released, making this a true universal library. Until then edit the 
*_reduce* fuction for your language and release as seperate language 
specific library.
