// LALRparser.scad which is a LALR X,Y Coordinate and Shape Specification Parser Engine Library
// Copyright (C) 2016 Bill Gertz
//
// Modified by Bill Gertz (billgertz) on 7 April 2016
// Version 0.8.0
//
// Version  Author          Change
// -------  -------------   ----------------------------------------------------------------------------
//  0.8.0   billgertz       Inital beta release
//
// Customizer View
// preview[view:south, tilt:top diagnol]
//
// License: 
//     This program is free software: you can redistribute it and/or modify it under the terms of the GNU 
//     General Public License as published by the Free Software Foundation, either version 3 of the 
//     License, or (at your option) any later version.
//
//     This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
//     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General 
//     Public License for more details.
//
//     You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
//
// Description:
//     This implements a LALR parser that parses (x,y) coordinate list or list of 
//     shapes for use with Thingiverse's Customizer into an OpenSCAD Vector. First
//     intended to specify holes or pins for circuit board mount point, or a list of
//     shapes to cut out of a panel. This parser allows free form input rather than
//     using an ugly and clumsy exhaustive field driven interface.
//
// X,Y Coordinate Specification:
//     List of coordinates in the form:
//          (<x>, <y>) 
//     List can be specifed white space insensitive using any combination of 
//     coordinate delimiters of <none>, "," or ";"
//     For example:
//       (12.1, -13.32) ( 5, -27)(.30,-1.0)
//       (3,2),(84.3,-2 ) , ( 11 , 1. 02)
//       ( 1 4, 2 7 . 0 5);(-  28.1,4) ;(-0 ,-.1  )
// 
//     The engine tolerates wild spacing around numbers, and even odd number
//     specifications, e.g. -0.0. However malformed lists and/or coordinates
//     are discarded. e.g. "(1-1,0)" "(1.0.0,7)" "(.,.3)" "(1,2)(1" "()"
//
// Shape Specification:
//     List of shapes (circle, rectangle or square) as follows:
//          cir(<diameter>)@(<x-center>,<y-center>)
//          rec(<width>, <height>)@(<x-center>, <y-center>)
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
//
// Notes:
//     This can be used as skeleton for different language parsers, but you
//     need to hand edit not only the token, grammar and fsa tables but embed
//     a bespoke _reduce function.
//
//     Unfortunaely the _reduce function must be declared for each LALR parser
//     The _parser could be specified as a function when OpenSCAD v2.0 is 
//     released, making this a true universal library. Until then edit the 
//     _reduce fuction for your language and release as seperate language 
//     specific library.

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

// List Types and Marker
//   The returned coordinate or shape list and list marker
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
//   $_parserStop set to step number to stop on
//       _parser returns undef if the parse fails
//       Typically this is becuase an expected symbol is encountered
//       while in a state. If _parser is dying try setting _parserStop
//       up in steps of 10 and backing off until you find the step 
//       just before it fails. Edit the FSA table to repair the fault.
$_parserStop = -1; 

// grammar 
//   Grammar of language expressed as derivative RHS symbols 
//   composed of LHS symbols (terminal tokens) or non-terminal
//   lexemes
//       List of grammar rules at a list of RHS as first element and 
//       a list of LHS composite symbols refactored to remove "or"
//       element from grammar rule. For example rule:
//           ShapeList -> ShapeList Sep Spec | Spec .
//       is expressed as two list items:
//           [ "ShapeList", [ "ShapeList", "Sep", "Spec] ],
//           [ "ShapeList", [ "Spec" ] ]
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

// parser
//   The LALR Finite State Automata (FSA) Table
//       A list of current states the describing the next _action and
//       _rule or _state depending on the encountered symbol (token or
//       lexeme. 
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
    [ [_eol, _reduce, 5], [";", _reduce, 5], [",", _reduce, 5], ["(", _reduce, 5] ],
    [ [_eol, _reduce, 3], [";", _reduce, 3], [",", _reduce, 3], ["sqr", _reduce, 3], ["rec", _reduce, 3], ["cir", _reduce, 3] ],
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

// tokens
//    List of all valid tokens that will be encountered
//    and tokenized from the input stream as either a
//    single character or sequence of character. First
//    element is the character or sequence to match and
//    second element is the token name
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
                 
// String and string to number operators
//   substr(<string>, <pos> [, <num>])
//         returns the partial string starting at <pos> (zero index) of <string> of <num> characters
//         returns to end of <string> if no <num> given
//         returns to end of <string> if <pos> + <num> is longer than <string>
//   _int(<string>)
//         converts an unsigned <string> integer to unsigned integer
//   _frac(<string>)
//         converts decimal part of float <string> into unsigned frational floating point number
//   int(<string>)
//         converts signed integer <string> to integer
//   float(<string>)
//         converts signed float <string> to float

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
//   push, unshift(<item>, <stack>)
//       push returns stack with <item> added to head of <stack>
//       unshit returns stack with <item> added to tail of <stack>
                 
function push(item, stack=undef) = stack == undef ? [item] : concat([item], stack);      
function unshift(item, stack=undef) = stack == undef ? [item] : concat(stack, [item]); 
                 
// pop, shift(<stack> [, <num>]) 
//      return stack after removing <num> items from <stack>
//      return undef on attempt to remove more than <num> items on <stack>
//      return empty stack when removing all items off stack (<num> = stack length)
              
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
    
// head, tail(<stack> [, <num>])
//       return null list if asked for zero items
//       return <num> of items from <stack>
//       return all items as list of stack if <num> more than length of stack
//       return single item from <stack> (not embeded in list) if no number passed
  
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

// _nextVector(<fsa>, <state>, <token>)
//   fetch triple of lookup token, _action and _state or _rule
//       Simply searches for the passed <token> in row <state>
//       from the LALR parser <fsa> table

function _nextVector(fsa, state, token) = fsa[state][search([ token[_name] ],fsa[state],1)[0]];

// _tokenize(<string>, <tokens>)
//   return input <string> as a stack of <tokens>
//       Creates a stack by looking up each character or matching
//       unbroken sequence of characters against <tokens> list.
//       Whitespace characters (" ", tab, newline, return) are
//       not tokenized but will stop character sequence token
//       recognition ("ci r " will not be recoginzed as shape
//       token "cir")
    
function _tokenize(string, tokens, pstring="", ostack=undef, i=0) = 
    let(
        token = tokens[search([string[i]],tokens)[0]],
        ptoken = tokens[search([pstring],tokens)[0]]
    )
    i < len(string) ? // keep tokeninzing until end of string
        ptoken[_name] == undef ?  // if the accumulated string doesn't match any sequence tokens
            search(string[i]," \t\n\r")[0] == undef ? // if the character isn't a whitespace
                token[_name] == undef ? // if the character doesn't match nat tokens add it to the accumulated string and continue
                    _tokenize(string, tokens, str(pstring, string[i]), ostack, i+1) 
                :
                    _tokenize(string, tokens, "", push(token, ostack), i+1) // if found in tokens then add token to stack and continue
            :
                _tokenize(string, tokens, "", ostack, i+1) // if a whitespace then clear the accumulated token and continue
        :
             _tokenize(string, tokens, "", push(ptoken, ostack), i) // if found a token from the accumulated string then add token and continue
    : len(pstring) == 0 ? // if at end of string add the end of input token and finish
        push(_endtoken, ostack)
    : undef // if somehow past end of string then return error (undef)
 ;

// _reduce(<rule>, <grammar>, <output stack>)
//   reduces <ostack> by <rule> number defined in <grammar>
//       Builds desired output lists by using elements from
//       output stack as defined in LHS of gramar rule. The
//       _reduce function depends on the desired output from
//       the parse. In this case it builds one of three lists
//       as outined in List Types and Markers discussed above.
//       The fuction works much like a case statement where
//       each case defines the reduction to build the output
//       based on each grammar rule.

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

// _parse(<token stack>, <grammar>, <fsa>)
//   reurn list output parsed according to the LALR parser <fsa>
//   table from the <token stack> using the defined <grammar>
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

// parse(<string>, <token>, <grammar>, <fsa>)
//   combine _toeknize and _parse into a single step by
//   parsing the given <string> using <token> and defined
//   <grammar> with LALR parser <fsa> table.
//
//   defaults to given tokens, grammar and paser tables in this
//   module
//       Verifies that all input elements are at least defined
//       before attempting to run.

function parse(string, tokens=tokens, grammar=grammar, fsa=parser) = 
    fsa == undef || grammar == undef || tokens == undef ?
        undef
    : _parse(_tokenize(string, tokens), grammar, fsa)
;

// Test Cases
coordString = "(11,- 2.15);(- 3 1 . 7 5, 12.222)(-1,11),(-0,-.04)";
echo(str("Parse of \"", coordString, "\" is ", parse(coordString)));
shapeString = "rec(5,4)@(11,- 2.15) cir(10)@(4.0,8.0) ;  sqr(30)@(40.0,-18.808)";
echo(str("Parse of \"", shapeString, "\" is ", parse(shapeString)));
blankString = "";
echo(str("Parse of \"", blankString, "\" is ", parse(blankString)));
badString = "rec(5,4)@(11,- 2.1 cir(10)@(4.0,8.0)";
echo(str("Parse of \"", badString, "\" is ", parse(badString)));
longString = "abcdefg1234567";
echo(str("Substring of \"", longString, "\" from 7 to end is ", substr(longString,7)));
echo(str("Substring of \"", longString, "\" from 5 for 4 is ", substr(longString,5,4)));
intString = "-12";
echo(str("Integer of \"", intString, "\" is ", int(intString)));
floatString = "-12.1";
echo(str("Float of \"", floatString, "\" is ", float(floatString)));

// Usage Examples
// constants to name returned List elements
type = 0;
list = 1;

name = 0;
param = 1;
coord = 2;

//parse the sample coord list string
coordList = parse("(-20,-20) (-40,-40) (-80,-80)");

// show example as linear extrude
if (coordList[type] == _coord) linear_extrude(height=20, center=true) {
    for(i=[ 0:len(coordList[list])-1 ]) {
        coord = coordList[list][i];
        
        echo(str("Drawing circle with radius 5 at ", coord));    
        translate (coord) circle(r=5);
    } 
}

//parse the sample shape list string
shapeList = parse("rec(20,40)@(10,0) cir(50)@(40,40) sqr(40)@(80,80)");

// show example as linear extrude
if (shapeList[type] == _shape) linear_extrude(height=20, center=true) {
    for(i=[ 0:len(shapeList[list])-1 ]) {
        shape = shapeList[list][i][name];
        parameter = shapeList[list][i][param];
        coord = shapeList[list][i][coord];
        
        echo(str("Drawing ", shape, " with parameter ", parameter, " at ", coord));
        
        if (shape == "cir") translate (coord) circle(d=parameter[0]);
        else if (shape == "sqr") translate (coord) square(size=parameter[0], center=true);
        else if (shape == "rec") translate (coord) square(size=parameter, center=true);
    } 
}