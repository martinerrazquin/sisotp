TP1: Memoria virtual en JOS
===========================

page2pa
-------
Primero se recibe pp, dir. en memoria de la pagina objetivo, y por otro lado se conoce pages que es la dir. en memoria de la primera. Como están definidas como arreglo, restar ambas devuelve el offset desde pages hasta pp, y como la primer página se direcciona al 0x0, la n-ava va a direccionarse al n*tam_página, y ahí es donde entra el PGSHIFT (que vale 12) que nos dice que la physical address donde empieza la n-ava página es 0xn000. 
...


boot_alloc_pos
--------------

...


page_alloc
----------

...


