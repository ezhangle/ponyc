grammar pony;

options
{
  output = AST;
  k = 1;
}

// Parser

module
  :  STRING? use* class_*
  ;

use
  :  'use' (ID '=')? (STRING | use_ffi) ('if' expr)?
  ;

use_ffi
  :  '@' (ID | STRING) type_args '(' params? ')' '?'?
  ;

class_
  :  ('type' | 'interface' | 'trait' | 'primitive' | 'class' | 'actor') ID type_params? const_params? cap? ('is' types)? STRING? members
  ;

members
  :  field* method*
  ;

field
  :  ('var' | 'let') ID oftype ('=' infix)?
  ;

method
  :  ('fun' | 'be' | 'new') cap? ID? type_params? const_params? '(' params? ')' oftype? '?'? STRING? ('=>' seq)?
  ;

oftype
  :  ':' type
  ;

types
  :  type (',' type)*
  ;

type
  :  atom_type ('->' type)?
  ;

atom_type
  :  'this' // only used for viewpoint adaptation
  |  'box' // only used for viewpoint adaptation
  |  '(' tuple_type ')'
  |  ID ('.' ID)? type_args? const_args? cap? ('^' | '!')? // nominal type
  ;

tuple_type
  :  (infix_type | '_') (',' (infix_type | '_'))*
  ;

infix_type
  :  type (('|' | '&') type)*
  ;

type_params
  :  '[' type_param (',' type_param)* ']'
  ;

type_param
  :  ID oftype? ('=' type)?
  ;

type_args
  :  '@[' type (',' type)* ']'
  ;

const_params
  :  '{' const_param (',' const_param)* '}'
  ;

const_param
  :  ID oftype ('=' infix)?
  ;

const_args
  :  '{' infix (',' infix)* '}'
  ;

cap
  :  'iso' | 'trn' | 'ref' | 'val' | 'box' | 'tag'
  ;

params
  :  param (',' param)*
  ;

param
  :  ID oftype ('=' infix)?
  |  '...'
  ;

seq
  :  expr+ jump?
  |  jump
  ;

expr
  :  assignment ';'?
  ;

jump
  :  'return' seq? // more than one expr here is an error
  |  'break' seq? // more than one expr here is an error
  |  'continue' seq? // sequences here are errors
  |  'error' seq? // sequences here are errors
  ;

assignment
  :  infix ('=' assignment)?
  ;

infix
  :  term ((binop term) | ('as' type))*
  ;

term
  :  local
  |  control
  |  postfix
  |  unop term
  ;

local
  :  ('var' | 'let') ID oftype?
  ;

control
  :  'if' seq 'then' seq (elseif | ('else' seq))? 'end'
  |  'match' seq case* ('else' seq)? 'end'
  |  'while' seq 'do' seq ('else' seq)? 'end'
  |  'repeat' seq 'until' seq ('else' seq)? 'end'
  |  'for' idseq 'in' seq 'do' seq ('else' seq)? 'end'
  |  'try' seq ('else' seq)? ('then' seq)? 'end'
  |  'with' withexpr (',' withexpr)* 'do' seq ('else' seq)? 'end'
  |  'recover' cap? seq 'end'
  |  '$scope' '(' (expr)+ ')' // For testing only
  |  '$seq' '(' (expr)+ ')' // For testing only
  ;

elseif
  :  'elseif' seq 'then' seq (elseif | ('else' seq))?
  ;

case
  :  '|' infix? ('where' seq)? ('=>' seq)?
  ;

withexpr
  :  idseq '=' seq
  ;

postfix
  :  atom
     (  '.' ID // member access
     |  '~' ID // partial application, syntactic sugar
     |  type_args // type arguments
     |  const_args // constant arguments
     |  '@(' positional? named? ')' // call
     )*
  ;

atom
  :  INT
  |  FLOAT
  |  STRING
  |  ID
  |  'this'
  |  '(' tuple ')' // tuple
  |  '[' ('as' type ':')? positional ']' // array
  |  'object' ('is' types)? members 'end' // object
  |  '@' (ID | STRING) type_args? '(' positional? ')' '?'? // ffi
  ;

idseq
  :  ID
  |  '_'
  |  '(' idseq (',' idseq)* ')'
  ;

tuple
  :  (seq | '_') (',' (seq | '_'))*
  ;

positional
  :  seq (',' seq)*
  ;

named
  :  'where' ID '=' seq (',' ID '=' seq)*
  ;

unop
  :  'not' | '-' | 'consume' (cap | '$borrowed')? | '&'
  ;

binop
  :  'and' | 'or' | 'xor' // logic
  |  '+' | '@-' | '*' | '/' | '%' // arithmetic
  |  '<<' | '>>' // shift
  |  'is' | 'isnt' | '==' | '!=' | '<' | '<=' | '>=' | '>' // comparison
  ;

/* Precedence

Value:
1. postfix
2. unop
3. binop
4. =
5. seq
6. ,

Type:
1. ->
2. & |
3. ,
*/

// Lexer

ID
  :  LETTER (LETTER | DIGIT | '_' | '\'')*
  |  '_' (LETTER | DIGIT | '_' | '\'')+
  ;

INT
  :  DIGIT+
  |  '0' 'x' HEX+
  |  '0' 'b' BINARY+
  |  '\'' (ESC | ~('\'' | '\\'))* '\''
  ;

FLOAT
  :  DIGIT+ ('.' DIGIT+)? EXP?
  ;

LINECOMMENT
  :  '//' ~('\n' | '\r')* '\r'? '\n' {$channel=HIDDEN;}
  ;

NESTEDCOMMENT
  :  '/*' ( ('/*') => NESTEDCOMMENT | ~'*' | '*' ~'/')* '*/'
  ;

WS
  :  ' ' | '\t' | '\r' | '\n'
  ;

STRING
  :  '"' ( ESC | ~('\\'|'"') )* '"'
  |  '"""' ~('"""')* '"""'
  ;

fragment
EXP
  :  ('e' | 'E') ('+' | '-')? DIGIT+
  ;

fragment
LETTER
  :  'a'..'z' | 'A'..'Z'
  ;

fragment
BINARY
  :  '0'..'1'
  ;

fragment
DIGIT
  :  '0'..'9'
  ;

fragment
HEX
  :  DIGIT | 'a'..'f' | 'A'..'F'
  ;

fragment
ESC
  :  '\\' ('a' | 'b' | 'e' | 'f' | 'n' | 'r' | 't' | 'v' | '\"' | '\\' | '0')
  |  HEX_ESC
  |  UNICODE_ESC
  |  UNICODE2_ESC
  ;

fragment
HEX_ESC
  :  '\\' 'x' HEX HEX
  ;

fragment
UNICODE_ESC
  :  '\\' 'u' HEX HEX HEX HEX
  ;

fragment
UNICODE2_ESC
  :  '\\' 'U' HEX HEX HEX HEX HEX HEX
  ;
