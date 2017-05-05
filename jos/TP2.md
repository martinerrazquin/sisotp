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

...
