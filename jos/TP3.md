
## static_assert

*¿Cómo y por qué funciona la macro static_assert que define JOS?*

En el estandar C99 se establece que las expresiones de cada case deben ser valores numéricos y no se deben repetir:

"(1739) The expression of each case label shall be an integer constant expression and no two of the case constant expressions in the same switch statement shall have the same value after conversion." -C99, 6.8.4.2

En el caso de que la expresión evaluada sea falsa (representado con el valor 0 en C) se tienen dos casos para el valor 0

~~~
static_assert(x)	switch (x) case 0: case (x):     con x=0
~~~

El compilador por ende lanza un error de casos duplicados (error: duplicate case value). Cuando la expresión es verdadera se tienen 2 casos distintos por lo que no se genera ningún error.

## env_return

*Al terminar un proceso su función umain() ¿dónde retoma la ejecución el kernel? Describir la secuencia de llamadas desde que termina umain() hasta que el kernel dispone del proceso.*

Notemos que se llama al umain del programa desde libmain en libmain.c. Al terminar umain, retorna aquí y luego llama a exit() que consiste en sys_env_destroy(0), la cual a su vez llama a env_destroy(0). Como es el proceso que estaba corriendo al principio, en env_destroy es liberado y se entra al scheduler.

*¿En qué cambia la función env_destroy() en este TP, respecto al TP anterior?*

En el tp anterior como había un solo proceso, simplemente se lo liberaba y se llamaba al monitor. Ahora primero debe chequear que no esté corriendo en otra cpu, si lo esta sólo lo marca como zombie y retorna. Si no está corriendo, o lo está pero en la cpu que ejecuta env_destroy, lo libera y si además era el segundo caso se setea el proceso actual como NULL y se llama al scheduler.

## sys_yield

*Leer y estudiar el código del programa user/yield.c. Cambiar la función i386_init() para lanzar tres instancias de dicho programa, y mostrar y explicar la salida de make qemu-nox.*

# COMPLETAR


## contador_env

*¿qué ocurrirá con [la página donde esté alojado el buffer VGA] en env_free() al destruir el proceso?*

# COMPLETAR

*¿qué código asegura que el buffer VGA físico no será nunca añadido a la lista de páginas libres?*

# COMPLETAR





# PARTE 2

# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR
# COMPLETAR

