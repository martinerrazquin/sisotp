
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


Salida:
~~~
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Hello, I am environment 00001002.
Back in environment 00001000, iteration 0.
Back in environment 00001001, iteration 0.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 1.
Back in environment 00001000, iteration 2.
Back in environment 00001001, iteration 2.
Back in environment 00001002, iteration 2.
Back in environment 00001000, iteration 3.
Back in environment 00001001, iteration 3.
Back in environment 00001002, iteration 3.
Back in environment 00001000, iteration 4.
All done in environment 00001000.
[00001000] exiting gracefully
[00001000] free env 00001000
Back in environment 00001001, iteration 4.
All done in environment 00001001.
[00001001] exiting gracefully
[00001001] free env 00001001
Back in environment 00001002, iteration 4.
All done in environment 00001002.
[00001002] exiting gracefully
[00001002] free env 00001002
No runnable environments in the system!
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
~~~

Las primeras 3 lineas indican la creación de los 3 nuevos procesos cuyos ID seran 1000, 1001 y 1002 respectivamente. Luego se imprime por pantalla un saludo para cada uno de los procesos. Dado que en yield.c se define que tras el saludo se llame a la función *sys_yield* el proceso cede la ejecución a otro que esté en espera. Así se pasa del proceso 1000 al 1001 y luego al 1002.

Tras realizar esto, cada proceso entra en un ciclo donde imprime por pantalla un mensaje y luego cede la ejecución. Así se va rotando del proceso 1000, 1001, 1002 y nuevamente al 1000. Así se van rotando la ejecución por 5 iteraciones tras las cuales el proceso termina su ejecución y es liberado. Cuando un proceso termina se hace un context switch a otro proceso para que siga ejecutandose normalmente.

## contador_env

*¿qué ocurrirá con [la página donde esté alojado el buffer VGA] en env_free() al destruir el proceso?*

Se liberará y será enviada (no devuelta, porque en un principio no había sido mapeada) a la lista de páginas libres.

*¿qué código asegura que el buffer VGA físico no será nunca añadido a la lista de páginas libres?*

Si al mapear toda la memoria, a las páginas que no deben ser mapeadas se les agrega una referencia extra, estas nunca serán devueltas a la lista.

## SYS_envid2env

*Explicar que pasa:*

*a)en JOS, si un proceso llama a sys_env_destroy(0)*

La función envid2env() devuelve al proceso actual cuando se le pasa el valor 0 como parámetro. Por ende, sys_env_destroy terminará el proceso que realizó la llamada a dicha función.

*b)en Linux, si un proceso llama a kill(0, 9)*

La funcion kill envía una señal determinada a un proceso o grupo de. El segundo parámetro es el identificador de la señal que en este caso en particular indica SIGKILL. Esta señal termina instantaneamente a un proceso. Como el primer parámetro es igual a 0 la señal se enviará a todos los procesos que pertenezcan al mismo grupo de grupos. Por ende se terminaran todos los procesos que pertenezcan al grupo del proceso que llamo a kill().

*c)JOS: sys_env_destroy(-1)*

**arreglar** No estoy seguro que pasaria en este caso. inc/env.h dice que un envid_t menor a 0 significa error. Por otro lado, envid2env() no hace ningun chequeo. Si funcionara bien se destruiria el ultimo proceso de la lista (el ENVX de -1 es 1111111111, y eso equivaldria al offset del ultimo proceso en el array envs).

*d)Linux: kill(-1, 9)*

El parametro -1 indica que la señal se enviará a todos los procesos sobre los cuales se tenga permiso. Esto incluye al proceso mismo (aunque por implementación la señal no se envia en este caso) y a los procesos hijos.

## dumbfork

*Tras leer con atención el código, se pide responder:*

*Si, antes de llamar a dumbfork(), el proceso se reserva a sí mismo una página con sys_page_alloc() ¿se propagará una copia al proceso hijo? ¿Por qué?*

Sí, porque sys_page_alloc la mapeará a una VA en el esp. de direcciones del padre, y dumbfork recorre todo este último duplicando al hijo.

*¿Se preserva el estado de solo-lectura en las páginas copiadas? Mostrar, con código en espacio de usuario, cómo saber si una dirección de memoria es modificable por el proceso, o no.*

No, porque duppage las mapea con permisos de RW siempre.

~~~
bool is_writable(void* va){
	
	return uvpt[PGNUM((uint32_t)va)] & (PTE_P | PTE_U |PTE_W);	
	
}
~~~

*Describir el funcionamiento de la función duppage().*

Duppage consta de 4 partes:

-page_alloc: reserva una página nueva en el esp. de direcciones del proceso dstenv, mapeada a la dirección addr. Lo hace con permisos de RW.

-page_map: mapea esta nueva página a la dirección UTEMP en el padre, también con permisos RW.

-memmove: copia los datos correspondientes a la página en addr (del padre) a la página en UTEMP (del padre), que es la mapeada como addr en el hijo.

-page_unmap: desmapea la página del padre, luego la única referencia la tiene el hijo.


*Supongamos que se añade a duppage() un argumento booleano que indica si la página debe quedar como solo-lectura en el proceso hijo:*

*	*indicar qué llamada adicional se debería hacer si el booleano es true*

Debería hacerse una segunda llamada a sys_page_map para setearle los permisos correctos (sin PTE_W en este caso).

*	*describir un algoritmo alternativo que no aumente el número de llamadas al sistema, que debe quedar en 3 (1 × alloc, 1 × map, 1 × unmap).*

Considerando que ahora se puede realizar un mapeo en donde se puede seleccionar como R-only pero teniendo en cuenta que no se puede mapear una página con más permisos que en el mapeo original, resulta:

*Como algoritmo*

-reservar una página en el padre con permisos de RW.

-copiar el contenido de la página.

-mapearla en el hijo con permisos de R.

-desmapearla en el padre.

*Como código (sin contemplar errores)*
~~~
void duppage2(envid_t dstenv, void *addr, bool r_only){
	int perm = PTE_P|PTE_U|PTE_W;
	sys_page_alloc(0,UTEMP,perm);
	memmove(UTEMP,addr,PGSIZE);
	if (r_only) perm = perm & ~PTE_W;
	sys_page_map(0,UTEMP,dstenv,addr,perm);
	sys_page_unmap(0,UTEMP);
}
~~~

*¿Por qué se usa ROUNDDOWN(&addr) para copiar el stack? ¿Qué es addr y por qué, si el stack crece hacia abajo, se usa ROUNDDOWN y no ROUNDUP?*

Dado que addr es una variable local, esta alojada en stack. Luego, si hacemos ROUNDDOWN(&addr) obtenemos la dirección de base de la página en la cual tenemos el SP, que es la que nos importa copiar; de hacer ROUNDUP y no estar alineado el SP a PGSIZE, se obtendría la página siguiente, que no tiene sentido recordando que nuestra intención es copiar el stack.

## contador_fork

*¿Funciona? ¿Qué está ocurriendo con el mapping de VGA_USER? ¿Dónde hay que arreglarlo?*

No. Lo que está ocurriendo es que la página física del buffer VGA es la que corresponde a una dirección física particular, pero dup_or_share (o duppage, o cualquiera de las usadas hasta ahora) para copiar una página con permisos RW reservaban una página nueva, por lo que nunca se escriben los datos en el buffer sino en otra página aleatoria. Para solucionarlo, hay que agregar al caso de los permisos R-only el caso de páginas no-copiables (que también deben ser sólo mapeadas) en la función para mapeo de páginas correspondiente, en este caso dup_or_share.

*¿Podría fork() darse cuenta, en lugar de usando un flag propio, mirando los flags PTE_PWT y/o PTE_PCD? (Suponiendo que env_setup_vm() los añadiera para VGA_USER).*

No, porque no son flags admitidos para syscall (que son los que estan en 1 en PTE_SYSCALL). Luego, cuando se duplica la página, estos flags no se preservan. Para preservarlos deben ser, o bien los ya establecidos, o alguno de los 3 de PTE_AVAIL.

