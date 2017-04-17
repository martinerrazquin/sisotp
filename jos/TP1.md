TP1: Memoria virtual en JOS
===========================

page2pa
-------
Primero se recibe pp, dir. en memoria de la página objetivo, y por otro lado se conoce pages que es la dir. en memoria de la primera. Como están definidas como arreglo, restar ambas devuelve el offset desde pages hasta pp, y como la primer página se direcciona al 0x0, la n-ava va a direccionarse a n*tam_página, y ahí es donde entra el PGSHIFT (que vale 12) que nos dice que la physical address donde empieza la n-ava página es 0xn000.
NOTA: Cuando me refiero a offset me refiero a la diferencia de índices. Para que se diera el valor en Bytes, deberían haberse casteado a void*, y ahí sería offset\*sizeof(página). 
...


boot_alloc_pos
--------------

...


page_alloc
----------
Page2pa devuelve la physical address de la página; en cambio page2kva devuelve la Kernel Virtual Address, es una dirección VIRTUAL que por mapeo se puede calcular sumando a la física el valor de KERNBASE.
...


