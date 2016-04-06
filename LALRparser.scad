
// constants used by LALR parser (do not edit)
_value = 0;
_name = 1;

_token = 0;
_action = 1;
_rule = 2;
_state = 2;

_accept = 0;
_goto = 1;
_reduce = 2;
_shift = 3;

_eol = "$$";
_endtoken = [undef, _eol];

_lhs = 0;
_rhs = 1;

// list type marker
//   the returned coordinate or shape list marker
//       The returned value from a string parse is a list of 
//       coordinates or shapes (see below). These lists are
//       stuffed into a list with the first (the zero index)
//       the value as defined below, and the second (one index]
//       the list.
//       For example:
//           Blank List ""
//             [ _blank ]
//           Coordinate List "(10,10),(20,20),(30,30):
//             [ _coord, [ [10,10], [20,20], [30,30] ] ]
//           Shape List "rec(3,3)@(10,10),cir(4)@(20,20),sqr(5)@(30,30)"
//             [ _shape, [ ["rec",[3,3],[10,10] ], [ "cir",[4],[20,20] ], ["sqr",[5],[30,30] ] ] ]
_blank = 0;
_coord = 1;
_shape = 2;

// debug globals
//   parserStop set to step number to stop on
//       _parser returns undef if the parse fails
//       Typically this is becuase an expected symbol is encountered
//       while in a state. If _parser is dying try setting _parserStop
//       up in steps of 10 and backing off until you find the step 
//       just before it fails. Edit the FSA table to repair the fault.

$_parserStop = -1; 

grammar = [
    [ "Start", ["ShapeList"] ],
    [ "Start", ["CoordList"] ],
    [ "Start", [] ],
    [ "ShapeList", ["ShapeList", "Sep", "Spec"] ],
    [ "ShapeList", ["Spec"] ],
    [ "CoordList", ["CoordList", "Sep", "Pair"] ],
    [ "CoordList", ["Pair"] ],
    [ "Spec", ["Shape", "@", "Pair"] ],
    [ "Shape", ["cir", "Single"] ],
    [ "Shape", ["rec", "Pair"] ],
    [ "Shape", ["sqr", "Single"] ],
    [ "Pair", ["(", "Float", ",", "Float", ")"] ],                 
    [ "Single", ["(", "Float", ")"] ],
    [ "Sep", [","] ],
    [ "Sep", [";"] ],
    [ "Sep", [] ],
    [ "Float", ["+Float"] ],
    [ "Float", ["-", "+Float"] ],
    [ "+Float", ["Integer"] ],
    [ "+Float", ["Integer", "Fraction"] ],
    [ "+Float", ["Fraction"] ],
    [ "Fraction", [".", "Digits"] ],
    [ "Integer", ["Digits"] ],
    [ "Digits", ["digit"] ],
    [ "Digits", ["Digits", "digit"] ]
] ;

parser = [
    [ [_eol, _reduce, 2], ["(", _shift, 10], ["sqr", _shift, 9], ["rec", _shift, 8], ["cir", _shift, 7], ["Start", _goto, 6], ["ShapeList", _goto, 5], ["CoordList", _goto, 4], ["Spec", _goto, 3], ["Shape", _goto, 2], ["Pair", _goto, 1] ],
    [ [_eol, _reduce, 6], [";", _reduce, 6], [",", _reduce, 6], ["(", _reduce, 6] ],
    [ ["@", _shift, 27] ],
    [ [_eol, _reduce, 4], [";", _reduce, 4], [",", _reduce, 4], ["sqr", _reduce, 4], ["rec", _reduce, 4], ["cir", _reduce, 4] ],
    [ [_eol, _reduce, 1], [";", _shift, 26], [",", _shift, 25], ["(", _reduce, 15], ["Sep", _goto, 24] ],
    [ [_eol, _reduce, 0], [";", _shift, 26], [",", _shift, 25], ["sqr", _reduce, 15], ["rec", _reduce, 15], ["cir", _reduce, 15], ["Sep", _goto, 23] ],
    [ [_eol, _accept, undef] ],
    [ ["(", _shift, 22], ["Single", _goto, 21] ],
    [ ["(", _shift, 10], ["Pair", _goto, 20] ],
    [ ["(", _shift, 22], ["Single", _goto, 19] ],
    [ ["digit", _shift, 18], [".", _shift, 17], ["-", _shift, 16], ["Float", _goto, 15], ["+Float", _goto, 14], ["Fraction", _goto, 13], ["Integer", _goto, 12], ["Digits", _goto, 11] ],
    [ ["digit", _shift, 36], [".", _reduce, 22], [",", _reduce, 22], [")", _reduce, 22] ],
    [ [".", _shift, 17], [",", _reduce, 18], [")", _reduce, 18], ["Fraction", _goto, 35] ],
    [ [",", _reduce, 20], [")", _reduce, 20] ],
    [ [",", _reduce, 16], [")", _reduce, 16] ], 
    [ [",", _shift, 34] ],
    [ ["digit", _shift, 18], [".", _shift, 17], ["+Float", _goto, 33], ["Fraction", _goto, 13], ["Integer", _goto, 12], ["Digits", _goto, 11] ],
    [ ["digit", _shift, 18], ["Digits", _goto, 32] ],
    [ ["digit", _reduce, 23], [".", _reduce, 23], [",", _reduce, 23], [")", _reduce, 23] ],
    [ ["@", _reduce, 10] ],
    [ ["@", _reduce, 9] ],
    [ ["@", _reduce, 8] ],
    [ ["digit", _shift, 18], [".", _shift, 17], ["-", _shift, 16], ["Float", _goto, 31], ["+Float", _goto, 14], ["Fraction", _goto, 13], ["Integer", _goto, 12], ["Digits", _goto, 11] ],
    [ ["sqr", _shift, 9], ["rec", _shift, 8], ["cir", _shift, 7], ["Spec", _goto, 30], ["Shape", _goto, 2] ],
    [ ["(", _shift, 10], ["Pair", _goto, 29] ],
    [ ["(", _reduce, 13], ["sqr", _reduce, 13], ["rec", _reduce, 13], ["cir", _reduce, 13] ],
    [ ["(", _reduce, 14], ["sqr", _reduce, 14], ["rec", _reduce, 14], ["cir", _reduce, 14] ],
    [ ["(", _shift, 10], ["Pair", _goto, 28] ],
    [ [_eol, _reduce, 7], [";", _reduce, 7], [",", _reduce, 7], ["sqr", _reduce, 7], ["rec", _reduce, 7], ["cir", _reduce, 7] ],
    [ [_eol, _reduce, 5], [";", _reduce, 5], [",", _reduce, 5] ],
    [ [_eol, _reduce, 3], [";", _reduce, 3], [",", _reduce, 3] ],
    [ [")", _shift, 38] ],
    [ ["digit", _shift, 36], [",", _reduce, 21], [")", _reduce, 21] ],
    [ [",", _reduce, 17], [")", _reduce, 17] ],
    [ ["digit", _shift, 18], [".", _shift, 17], ["-", _shift, 16], ["Float", _goto, 37], ["+Float", _goto, 14], ["Fraction", _goto, 13], ["Integer", _goto, 12], ["Digits", _goto, 11] ],
    [ [",", _reduce, 19], [")", _reduce, 19] ],
    [ ["digit", _reduce, 24], [".", _reduce, 24], [",", _reduce, 24], [")", _reduce, 24] ],
    [ [")", _shift, 39] ],
    [ ["@", _reduce, 12] ],
    [ [_eol, _reduce, 11], [";", _reduce, 11], [",", _reduce, 11], ["(", _reduce, 11], ["@", _reduce, 11], ["sqr", _reduce, 11], ["rec", _reduce, 11], ["cir", _reduce, 11] ]
] ;

tokens = [
    ["(","("],
    [")",")"],
    [",",","],
    [";",";"],
    [".","."],
    ["-","-"],
    ["@","@"],
    for(i=[0:9]) [str(i),"digit"],
    ["cir", "cir"],
    ["rec", "rec"],
    ["sqr", "sqr"]
] ;
                 
// String to number operators
// _int
//     converts string integer to unsigned integer
// _frac
//     converts decimal part of float string into unsigned frational floating point number
// int
//     converts signed integer string to integer
// float
//      converts signed float string to float

function substr(string, start=0, length=undef) =
    let(
        len = length == undef ? 
            len(string) - start 
        : start + length > len(string) ? 
            start + length - len(string) + 1
        : length
   ) 
    len > 0 ? 
        str(string[start], substr(string, start + 1, len - 1)) 
    : ""
;
  
function int(string) =
    let(
        sign = string[0] == "-" ? -1 : 1, 
        start = string[0] == "-" ? 1 : 0
    )
    sign * _int(substr(string,start))
;
    
function float(string) =
    let(
        sign = string[0] == "-" ? -1 : 1, 
        start = string[0] == "-" ? 1 : 0,
        radixes = search(".",string,0)
    )
    len(radixes) > 1 ?
        undef
    : sign * (_int(substr(string, start, radixes[0][0]-start)) + _frac(substr(string, radixes[0][0]+1)))
;
   
function _int(string, i=0, carry=0) =
    let(
        digit = search(string[i], "0123456789")[0]
    )
    i == len(string) ? 
		carry
    : digit == undef ? undef : carry + _int(string, i+1, digit * pow(10,len(string)-i-1))
;                  

function _frac(string, i=0, carry=0) =
    let(
        digit = search(string[i], "0123456789")[0]
    )
	i == len(string) ? 
		carry
    : digit == undef ? undef : carry + _frac(string, i+1, digit * pow(10,-i-1))
;        

// Stack operators
//
// push, unshift
//     push retrns stack with item added to head of stack
//     unshit returns stack with item added to tail of stack
                 
function push(item, stack=undef) = stack == undef ? [item] : concat([item], stack);      
function unshift(item, stack=undef) = stack == undef ? [item] : concat(stack, [item]); 
                 
// pop, shift 
//    return undef on attempt to remove more items than on stack
//    return empty stack when removing all items off stack
              
function pop(stack, num=1) = 
    let(
        length = len(stack)
     ) 
     num > length ? 
         undef
     : num == length ?
         [] 
     : [ for(i=[num:length-1]) stack[i] ]
;
        
function shift(stack, num=1) = 
    let(
        length = len(stack)
    ) 
    num > length ? 
        undef 
    : num == length ? 
        [] 
    : [ for(i=[0:length-num-1]) stack[i] ]
;
    
// head, tail
//    return null list if asked for zero items
//    return number of requested items if number passed
//    return all items as list of stack if attempt to ask for more items than in stack
//    return single item (not embeded in list) if no number passed
  
function head(stack, num=undef) = 
    let(
        run = min(len(stack), num)
    ) 
    num == undef ?
        stack[0] 
    : num == 0 ? 
        [] 
    : [ for(i=[0:run-1]) stack[i] ]
;
    
function tail(stack, num=undef) = 
    let(
        run = min(len(stack), num),
        length = len(stack)
    ) 
    num == undef ? 
        stack[length-1] 
    : num == 0 ? 
        [] 
    : [ for(i=[run:-1:1]) stack[length-i] ]
;

function _nextVector(ptable, state, token) = ptable[state][search([ token[_name] ],ptable[state],1)[0]];
    
function _tokenize(string, tokens, pstring="", ostack=undef, i=0) = 
    let(
        token = tokens[search([string[i]],tokens)[0]],
        ptoken = tokens[search([pstring],tokens)[0]]
    )
    i < len(string) ?
        ptoken[_name] == undef ?
            search(string[i]," \t\n\r")[0] == undef ?
                token[_name] == undef ? 
                    _tokenize(string, tokens, str(pstring, string[i]), ostack, i+1) 
                :
                    _tokenize(string, tokens, "", push(token, ostack), i+1)
            :
                _tokenize(string, tokens, "", ostack, i+1)
        :
             _tokenize(string, tokens, "", push(ptoken, ostack), i)
    : len(pstring) == 0 ?
        push(_endtoken, ostack)
    : undef
 ;
 
function _reduce(rule, grammar, ostack) =
    let(
        lexeme = grammar[rule][_lhs],
        count = len(grammar[rule][_rhs]),
        tokens = tail(ostack, count),
        wstack = shift(ostack, count)
    )
    // case rule of
    rule == undef ?
        undef
    : rule == 0 ? // mark that a shape list is returned by element zero eq to _shape
        [_shape, tail(ostack)[_value]]
    : rule == 1 ? // coordinate list is returned by element zero eq to _coord
        [_coord, tail(ostack)[_value]]
    : rule == 2 ? // blank list (null list) is returned by element zero eq to _blank
        [_blank]
    : rule == 3 ? // add the Shape to the SpecList
        unshift([ unshift(tokens[2][_value], tokens[0][_value]), lexeme ], wstack)
    : rule == 4 ? // embed Shape in SpecList 
        unshift([ [tokens[0][_value]], lexeme ], wstack)
    : rule == 5 ? // add the Pair to the CoordList
        unshift([ unshift(tokens[2][_value], tokens[0][_value]), lexeme ], wstack)
    : rule == 6 ? // embed Pair in CoordList 
        unshift([ [tokens[0][_value]], lexeme ], wstack)
    : rule == 7 ? // turn into Spec (shape and location vector)
        unshift([ [ for(i=[0:len(tokens)-2])tokens[0][_value][i], tokens[2][_value] ], lexeme ], wstack)
    : rule == 8 || rule == 9 || rule == 10 ? // turn into Shape (name and parameters vector)
        unshift([ [tokens[0][_name], tokens[1][_value]], lexeme ], wstack)
    : rule == 11 ?  // turn parenthetical comma seperated x,y into vector Pair
        unshift([ [tokens[1][_value], tokens[3][_value]], lexeme ], wstack)
    : rule == 12 ?  // turn parenthetical value into vector Single
        unshift([ [tokens[1][_value]], lexeme ], wstack)
    : rule == 17 ?  // negate the +Float to make Float
        unshift([ -tokens[1][_value], lexeme ], wstack)
    : rule == 19 ?  // add the fractional to the integer to make +Float
        unshift([ tokens[0][_value] + tokens[1][_value], lexeme ], wstack)
    : rule == 21 ?  // convert numeric string behind decimal point into Fraction
        unshift([ _frac(tokens[1][_value]), lexeme ], wstack)
    : rule == 22 ?  // convert numeric string into Integer
        unshift([ _int(tokens[0][_value]), lexeme ], wstack)
    : rule == 24 ?  // concatenate digit to make Digits 
        unshift([ str(tokens[0][_value], tokens[1][_value]), lexeme ], wstack)
    // else just update the lexeme but leave the value unchanged
    : unshift([ tokens[0][_value], lexeme ], wstack)
;

function _parse(tstack, grammar, fsa, sstack=[0], ostack=undef, step=0) =
    let(
         token = tail(tstack),
         state = head(sstack),
         nextVector = _nextVector(fsa, state, token),
         action = nextVector[_action],
         rule = nextVector[_rule]
    )
    step == $_parserStop ? // shortcut for setting up debugging - set global $_parserStop to problem parse step to debug parsing
        str("===> DEBUG: Parser stopped at ", step, ": token: ", token, ", state: ", state, ", nextVector: ", nextVector, ", sStack: ", sstack, ", tStack: ", tstack, ", oStack: ", ostack)
    : len(tstack) == 0 ?  // if we've exhausted the token stack something has gone horribly wrong
        undef
    : action == _accept ? // _accept action simply outputs the output stack
        ostack
    : action == _goto ?   // _goto action shifts the token stack and pushes the next state on the state stack
        _parse(shift(tstack), grammar, fsa, push(nextVector[_state], sstack), ostack, step+1)
    : action == _shift ?  // _shift action shifts token stack, pushes the next state on the state stack, moves the token to the operation stack
        _parse(shift(tstack), grammar, fsa, push(nextVector[_state], sstack), unshift(token, ostack), step+1)
    : action == _reduce ? // _reduce action pops the state stack the number of tokens from the grammar rule RHS, shifts the LHS token into the token stack and reduces the operations stack
        _parse(unshift([undef, grammar[rule][_lhs]], tstack), grammar, fsa, pop(sstack,len(grammar[rule][_rhs])), _reduce(rule, grammar, ostack), step+1)
    : undef // otherwise the action is undefined or FSA table is mangled
 ;   

// LALR X,Y Coordinate and Shape Specification Parser Engine
//     Unfortunaely the reduce routine must be hand tuned for each LALR parser
//     This implementation parsers (x,y) coordinate list (from Customizer) into
//     a list of point or a list of shapes. Intended to specify circuit board
//     mount point, or a list of shapes to cut out of an end panel. Developed 
//     parser to allow free form input rather than use and ugly and clumsy
//     exhaustive field driven interface.
//
// X,Y Coordinate Specifications
//     List of coordinates in the form:
//          (<x>, <y>) 
//     List can be specifed white space insensitive using any combination of 
//     coordinate delimiters of <none>, "," or ";"
//     For example:
//       (12.1, -13.32), ( 5, -27),(.30,-1.0)
//       (3,2),(84.3,-2 ) , ( 11 , 1. 02)
//       ( 1 4, 2 7 . 0 5);(-  28.1,4) ;(-0 ,-.1  )
// 
//     The engine tolerates wild spacing around numbers, and even odd number
//     specifications, e.g. -0.0. However malformed lists and/or coordinates
//     are discarded. e.g. "(1-1,0)" "(1.0.0,7)" "(.,.3)" "(1,2)(1" "()"
//
// Shape Specification
//     List of shapes (circle, rectangle or aquare) as follows:
//          cir(<diameter>)@(<x-center>,<y-center>)
//          rec(<height>, <width>)@(<x-center>, <y-center>)
//          sqr(<side>)@(<x-center>, <y-center>)
//     As with coordinates, list can be specifed white space insensitive using
//     any combination of coordinate delimiters of <none>, "," or ";"
//     For example:
//       cir(5)@(12.1, -13.32) rec( 5, -27) @ (.30,-1.0)
//       rec (3,2) @(84.3,-2 ) , sqr( 11 ) @ ( - 2, 1. 02)
//       rec( 1 4, 2 7 . 0 5)@(-  28.1,4) ;cir(34)@(-0 ,-.1  )
// 
//     The engine tolerates wild spacing around numbers, and even odd number
//     specifications, e.g. -0.0. However malformed lists and/or shapes are 
//     discarded. e.g. "cir(1-1)@(1,1)" "sqr(1,1)*(1.0.1,6)" "rec(.,.3)@(1,1)"

function parse(string, tokens, grammar, fsa) = 
    fsa == undef || grammar == undef || tokens == undef ?
        undef
    : _parse(_tokenize(string, tokens), grammar, fsa)
;

coordString = "(11,- 2.15)(- 3 1 . 7 5, 12.222);(-1,11),(-0,-.04)";
echo(str("Parse of \"", coordString, "\" is ", parse(coordString, tokens, grammar, parser)));
shapeString = "rec(5,4)@(11,- 2.15) cir(10)@(4.0,8.0) ;  sqr(30)@(40.0,-18.808)";
echo(str("Parse of \"", shapeString, "\" is ", parse(shapeString, tokens, grammar, parser)));
blankString = "";
echo(str("Parse of \"", blankString, "\" is ", parse(blankString, tokens, grammar, parser)));
badString = "rec(5,4)@(11,- 2.1 cir(10)@(4.0,8.0)";
echo(str("Parse of \"", badString, "\" is ", parse(badString, tokens, grammar, parser)));
longString = "abcdefg1234567";
echo(str("Substring of \"", longString, "\" from 7 to end is ", substr(longString,7)));
longString = "abcdefg1234567";
echo(str("Substring of \"", longString, "\" from 5 for 4 is ", substr(longString,5,4)));
intString = "-12";
echo(str("Integer of \"", intString, "\" is ", int(intString)));
floatString = "-12.1";
echo(str("Float of \"", floatString, "\" is ", float(floatString)));