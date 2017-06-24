
Tarea: static_assert

Responder: ¿cómo y por qué funciona la macro static_assert que define JOS?

En el estandar C99 se establece que las expresiones de cada case deben ser valores numéricos y no se deben repetir:

"(1739) The expression of each case label shall be an integer constant expression and no two of the case constant expressions in the same switch statement shall have the same value after conversion." -C99, 6.8.4.2

En el caso de que la expresión evaluada sea falsa (representado con el valor 0 en C) se tienen dos casos para el valor 0
static_assert(x)	switch (x) case 0: case (x):     con x=0

El compilador por ende lanza un error de casos duplicados (error: duplicate case value). Cuando la expresión es verdadera se tienen 2 casos distintos por lo que no se genera ningún error.
=================================================================
