TP2: Procesos de usuario
========================

env_alloc
---------
¿Qué identificadores se asignan a los primeros 5 procesos creados? (Usar base hexadecimal.)

0x1001
0x1002
0x1003
0x1004
0x1005
...
Supongamos que al arrancar el kernel se lanzan NENV proceso a ejecución. A continuación se destruye el proceso asociado a envs[630] y se lanza un proceso que cada segundo muere y se vuelve a lanzar. ¿Qué identificadores tendrá este proceso en sus sus primeras cinco ejecuciones?

0x2276
0x3276
0x4276
0x5276
0x6276



env_init_percpu
---------------
¿Cuántos bytes escribe la función lgdt, y dónde?
¿Qué representan esos bytes?

La función lgdt escribe 6 bytes en el registro GDTR (Global Descriptor Table Register).
Los 2 bytes mas bajos indican el tamaño de la GDT mientras que los 4 bytes mas altos indican la posición en memoria de la tabla.

...
Dos hilos distintos ejecutándose en paralelo ¿podrían usar distintas GDT?





env_pop_tf
----------
-¿Qué hay en (%esp) tras el primer movl de la función?
Se pasa al esp la trapframe address (&tf), luego al dereferenciarlo se accede al mismo.
-¿Qué hay en (%esp) justo antes de la instrucción iret? ¿Y en 8(%esp)?
Está el valor de %eip a donde volver terminado el trap. En (%esp)+8 se encuentra el valor guardado de %esp. 
-En la documentación de iret en [IA32-2A] se dice: "If the return is to another privilege level, the IRET instruction also pops the stack pointer and SS from the stack, before resuming program execution."
¿Cómo puede determinar la CPU si hay un cambio de ring (nivel de privilegio)?
Porque popea del stack el code segment, luego puede chequear el CPL para saber en que ring corre el código al que se cambia.
...


gdb_hello
---------
2-
EAX=003bc000 EBX=00010074 ECX=f03bc000 EDX=00000217
ESI=00010074 EDI=00000000 EBP=f010dfd8 ESP=f010dfbc
EIP=f0102e90 EFL=00000092 [--S-A--] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0010 00000000 ffffffff 00cf9300 DPL=0 DS   [-WA]
CS =0008 00000000 ffffffff 00cf9a00 DPL=0 CS32 [-R-]

3-
$1 = (struct Trapframe *) 0xf01d8000

4-
(gdb) x/17x tf
0xf01d8000:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01d8010:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01d8020:	0x00000023	0x00000023	0x00000000	0x00000000
0xf01d8030:	0x00800020	0x0000001b	0x00000000	0xeebfe000
0xf01d8040:	0x00000023

5-

disas
si 4

6-
(gdb) x/17x $sp
0xf01d8000:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01d8010:	0x00000000	0x00000000	0x00000000	0x00000000
0xf01d8020:	0x00000023	0x00000023	0x00000000	0x00000000
0xf01d8030:	0x00800020	0x0000001b	0x00000000	0xeebfe000
0xf01d8040:	0x00000023

7-
En la primer fila estan los registros %edi, %esi, %ebp y el %esp. El %edi y %esi son registros de indexacion, siendo el %edi el indice de destino y el otro es el indice de origen (o source). Pueden ser usados para copiar data desde la direccion apuntada por el origen a la direccion indicada por el destino. El %ebp es el frame pointer y apunta al comienzo del frame de la función actual. El %ebp junto con un offset puede ser usado para obtener los parámetros de la función actual.

Luego estan los registros multipropositos %ebx, %ecx, %edx y por ultimo %eax. Estos registros son multipropositos por lo que se los puede usar para devolver valores (como %eax en la convención de llamadas) o para hacer cálculos.

En la tercer fila se encuentran los valores de %es, %ds, el numero de trap y tf-errno. %es y %ds son registros de segmentos de 16 bits (se les agrega padding para llenar los 32 bits). Son usados para la segmentación de x86. %es es el segmento extra, determinado por el programador y usado como le convenga, y %ds es el segmento de datos, donde se almacenan variables estaticas (tanto globales como locales). tf_errno almacena el código de error del proceso en caso de ser necesario. El numero de trap informa que se debe hacer con el trap y que handler debe hacerse cargo.

En la cuarta fila se encuentra el %eip, el valor de %cs (con padding), luego se encuentra %eflags y por ultimo el stack pointer (%esp). El registro %eip es el instruction pointer que indica que instrucción se debe ejecutar. %cs indica el segmento de código y es usado por el mecanismo de segmentación para encontrar instrucciones a ejecutar. Ademas se almacena el nivel de control (kernel o usuario) en este registro. El %esp es el stack pointer e indica la posición actual del stack. El stack es usado para guardar valores de funciones, pasar parámetros al llamar a funciones, devolver valores en una función, etc. %eflags almacena flags para el control de input/output, flags como el overflow, cero o el carry.

El ultimo valor es el %ss (con padding). Esto es el segmento de stack y es usado junto a la segmentación para indicar el frame de la función actual.

Los registros %es, %ss, %ds, %ss se usan en el modo kernel como modo de direccionamiento debido al uso de segmentación. Luego al pasar a protected mode son usados para controlar el Global descriptor table (GDT).

Los valores seteados son: %es, %ds, %eip, %cs, %esp, %ss.
 
Salvando el eip, tienen el valor asignado por env_alloc.
Del eip, el valor que importa es el asignado por load_icode, correspondiente al entry. Cualquier instruccion ejecutada por usuario deberia ser relativa a este mismo.
..
8-
EAX=00000000 EBX=00000000 ECX=00000000 EDX=00000000
ESI=00000000 EDI=00000000 EBP=00000000 ESP=f01d8030
EIP=f0102e9f EFL=00000096 [--S-AP-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0023 00000000 ffffffff 00cff300 DPL=3 DS   [-WA]
CS =0008 00000000 ffffffff 00cf9a00 DPL=0 CS32 [-R-]

La instrucción popa setea los registros de proposito general con los valores encontrados en el stack. Al momento de la llamada el stack pointer apunta al Trapframe, en particular a todos los valores de registros que tiene guardados.

9-
(gdb) p $eip
$3 = (void (*)()) 0x800020

(gdb) p $eip
$4 = (void (*)()) 0x800020 <_start>

EAX=00000000 EBX=00000000 ECX=00000000 EDX=00000000
ESI=00000000 EDI=00000000 EBP=00000000 ESP=eebfe000
EIP=00800020 EFL=00000002 [-------] CPL=3 II=0 A20=1 SMM=0 HLT=0
ES =0023 00000000 ffffffff 00cff300 DPL=3 DS   [-WA]
CS =001b 00000000 ffffffff 00cffa00 DPL=3 CS32 [-R-]

Al cambiar de contexto, el %eip cambia para apuntar a las nuevas instrucciones que deben ser ejecutadas. De la misma forma el stack pointer se modificó al estar en una función distinta (y nuevas direcciones de memoria). El otro cambio importante es que el CPL paso de 0 (kernel mode) a 3 (user mode).


10-

===================================================================================
kern_idt
---------
¿Cómo decidir si usar TRAPHANDLER o TRAPHANDLER_NOEC? ¿Qué pasaría si se usara solamente la primera?
-Leyendo la bibliografia [IA-3A] y revisando si la interrupcion/excepción pushea al stack un código de error o no. Si se usara solamente TRAPHANDLER el programa no funcionaría debido a que la CPU no siempre pushea un código de error mientras que el kernel espera que el Trapframe tenga uno guardado. Al no haber un código de error el trapframe que recibe la función trap() no sería correcto.

¿Qué cambia, en la invocación de handlers, el segundo parámetro (istrap) de la macro SETGATE? ¿Por qué se elegiría un comportamiento u otro durante un syscall?
-El parámetro indica si la entrada de la IDT corresponde a un interrupt gate o trap gate. El interrupt elimina el flag IF para evitar que haya interrupciones mientras el handler se ejecuta. Los interrupts son lanzados de forma asincronica, es decir que se pueden lanzar en cualquier momento.

Leer user/softint.c y ejecutarlo con make run-softint-nox. ¿Qué excepción se genera? Si hay diferencias con la que invoca el programa… ¿por qué mecanismo ocurre eso, y por qué razones?
-Se genera la excepcion "Page Fault".

user_evilhello
--------
¿En qué se diferencia el código de la versión en evilhello.c mostrada arriba?
-En dónde se hace el desreferenciamiento. Uno lo hace el kernel durante la syscall y el otro el usuario antes de llamarla.

¿En qué cambia el comportamiento durante la ejecución? ¿Por qué? ¿Cuál es el mecanismo?
-Por lo dicho antes, cuando en el segundo código se intenta acceder a la dirección la pte no tendrá los permisos necesarios y ocurrirá un fault. En el primero en cambio, es el kernel el que accede por lo que siempre tiene permisos de acceso. Si no se chequea explícitamente que los argumentos pasados sean válidos el primero no tendrá ningún fault.


