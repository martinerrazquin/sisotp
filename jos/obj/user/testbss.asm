
obj/user/testbss:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 ab 00 00 00       	call   8000dc <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800039:	68 14 0e 80 00       	push   $0x800e14
  80003e:	e8 ba 01 00 00       	call   8001fd <cprintf>
  800043:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < ARRAYSIZE; i++)
  800046:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004b:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800052:	00 
  800053:	74 12                	je     800067 <umain+0x34>
			panic("bigarray[%d] isn't cleared!\n", i);
  800055:	50                   	push   %eax
  800056:	68 8f 0e 80 00       	push   $0x800e8f
  80005b:	6a 11                	push   $0x11
  80005d:	68 ac 0e 80 00       	push   $0x800eac
  800062:	e8 bd 00 00 00       	call   800124 <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800067:	83 c0 01             	add    $0x1,%eax
  80006a:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80006f:	75 da                	jne    80004b <umain+0x18>
  800071:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800076:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  80007d:	83 c0 01             	add    $0x1,%eax
  800080:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800085:	75 ef                	jne    800076 <umain+0x43>
  800087:	b8 00 00 00 00       	mov    $0x0,%eax
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  80008c:	3b 04 85 20 20 80 00 	cmp    0x802020(,%eax,4),%eax
  800093:	74 12                	je     8000a7 <umain+0x74>
			panic("bigarray[%d] didn't hold its value!\n", i);
  800095:	50                   	push   %eax
  800096:	68 34 0e 80 00       	push   $0x800e34
  80009b:	6a 16                	push   $0x16
  80009d:	68 ac 0e 80 00       	push   $0x800eac
  8000a2:	e8 7d 00 00 00       	call   800124 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000a7:	83 c0 01             	add    $0x1,%eax
  8000aa:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000af:	75 db                	jne    80008c <umain+0x59>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000b1:	83 ec 0c             	sub    $0xc,%esp
  8000b4:	68 5c 0e 80 00       	push   $0x800e5c
  8000b9:	e8 3f 01 00 00       	call   8001fd <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000be:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000c5:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000c8:	83 c4 0c             	add    $0xc,%esp
  8000cb:	68 bb 0e 80 00       	push   $0x800ebb
  8000d0:	6a 1a                	push   $0x1a
  8000d2:	68 ac 0e 80 00       	push   $0x800eac
  8000d7:	e8 48 00 00 00       	call   800124 <_panic>

008000dc <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	83 ec 08             	sub    $0x8,%esp
  8000e2:	8b 45 08             	mov    0x8(%ebp),%eax
  8000e5:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  8000e8:	c7 05 20 20 c0 00 00 	movl   $0x0,0xc02020
  8000ef:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000f2:	85 c0                	test   %eax,%eax
  8000f4:	7e 08                	jle    8000fe <libmain+0x22>
		binaryname = argv[0];
  8000f6:	8b 0a                	mov    (%edx),%ecx
  8000f8:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  8000fe:	83 ec 08             	sub    $0x8,%esp
  800101:	52                   	push   %edx
  800102:	50                   	push   %eax
  800103:	e8 2b ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800108:	e8 05 00 00 00       	call   800112 <exit>
}
  80010d:	83 c4 10             	add    $0x10,%esp
  800110:	c9                   	leave  
  800111:	c3                   	ret    

00800112 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800112:	55                   	push   %ebp
  800113:	89 e5                	mov    %esp,%ebp
  800115:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  800118:	6a 00                	push   $0x0
  80011a:	e8 26 0a 00 00       	call   800b45 <sys_env_destroy>
}
  80011f:	83 c4 10             	add    $0x10,%esp
  800122:	c9                   	leave  
  800123:	c3                   	ret    

00800124 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800124:	55                   	push   %ebp
  800125:	89 e5                	mov    %esp,%ebp
  800127:	56                   	push   %esi
  800128:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800129:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80012c:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800132:	e8 30 0a 00 00       	call   800b67 <sys_getenvid>
  800137:	83 ec 0c             	sub    $0xc,%esp
  80013a:	ff 75 0c             	pushl  0xc(%ebp)
  80013d:	ff 75 08             	pushl  0x8(%ebp)
  800140:	56                   	push   %esi
  800141:	50                   	push   %eax
  800142:	68 dc 0e 80 00       	push   $0x800edc
  800147:	e8 b1 00 00 00       	call   8001fd <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80014c:	83 c4 18             	add    $0x18,%esp
  80014f:	53                   	push   %ebx
  800150:	ff 75 10             	pushl  0x10(%ebp)
  800153:	e8 54 00 00 00       	call   8001ac <vcprintf>
	cprintf("\n");
  800158:	c7 04 24 aa 0e 80 00 	movl   $0x800eaa,(%esp)
  80015f:	e8 99 00 00 00       	call   8001fd <cprintf>
  800164:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800167:	cc                   	int3   
  800168:	eb fd                	jmp    800167 <_panic+0x43>

0080016a <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80016a:	55                   	push   %ebp
  80016b:	89 e5                	mov    %esp,%ebp
  80016d:	53                   	push   %ebx
  80016e:	83 ec 04             	sub    $0x4,%esp
  800171:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800174:	8b 13                	mov    (%ebx),%edx
  800176:	8d 42 01             	lea    0x1(%edx),%eax
  800179:	89 03                	mov    %eax,(%ebx)
  80017b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80017e:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800182:	3d ff 00 00 00       	cmp    $0xff,%eax
  800187:	75 1a                	jne    8001a3 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  800189:	83 ec 08             	sub    $0x8,%esp
  80018c:	68 ff 00 00 00       	push   $0xff
  800191:	8d 43 08             	lea    0x8(%ebx),%eax
  800194:	50                   	push   %eax
  800195:	e8 61 09 00 00       	call   800afb <sys_cputs>
		b->idx = 0;
  80019a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001a0:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001a3:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001a7:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001aa:	c9                   	leave  
  8001ab:	c3                   	ret    

008001ac <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001ac:	55                   	push   %ebp
  8001ad:	89 e5                	mov    %esp,%ebp
  8001af:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001b5:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001bc:	00 00 00 
	b.cnt = 0;
  8001bf:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001c6:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001c9:	ff 75 0c             	pushl  0xc(%ebp)
  8001cc:	ff 75 08             	pushl  0x8(%ebp)
  8001cf:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001d5:	50                   	push   %eax
  8001d6:	68 6a 01 80 00       	push   $0x80016a
  8001db:	e8 86 01 00 00       	call   800366 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001e0:	83 c4 08             	add    $0x8,%esp
  8001e3:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001e9:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001ef:	50                   	push   %eax
  8001f0:	e8 06 09 00 00       	call   800afb <sys_cputs>

	return b.cnt;
}
  8001f5:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001fb:	c9                   	leave  
  8001fc:	c3                   	ret    

008001fd <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001fd:	55                   	push   %ebp
  8001fe:	89 e5                	mov    %esp,%ebp
  800200:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800203:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800206:	50                   	push   %eax
  800207:	ff 75 08             	pushl  0x8(%ebp)
  80020a:	e8 9d ff ff ff       	call   8001ac <vcprintf>
	va_end(ap);

	return cnt;
}
  80020f:	c9                   	leave  
  800210:	c3                   	ret    

00800211 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
  800214:	57                   	push   %edi
  800215:	56                   	push   %esi
  800216:	53                   	push   %ebx
  800217:	83 ec 1c             	sub    $0x1c,%esp
  80021a:	89 c7                	mov    %eax,%edi
  80021c:	89 d6                	mov    %edx,%esi
  80021e:	8b 45 08             	mov    0x8(%ebp),%eax
  800221:	8b 55 0c             	mov    0xc(%ebp),%edx
  800224:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800227:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80022a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80022d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800232:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800235:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800238:	39 d3                	cmp    %edx,%ebx
  80023a:	72 05                	jb     800241 <printnum+0x30>
  80023c:	39 45 10             	cmp    %eax,0x10(%ebp)
  80023f:	77 45                	ja     800286 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800241:	83 ec 0c             	sub    $0xc,%esp
  800244:	ff 75 18             	pushl  0x18(%ebp)
  800247:	8b 45 14             	mov    0x14(%ebp),%eax
  80024a:	8d 58 ff             	lea    -0x1(%eax),%ebx
  80024d:	53                   	push   %ebx
  80024e:	ff 75 10             	pushl  0x10(%ebp)
  800251:	83 ec 08             	sub    $0x8,%esp
  800254:	ff 75 e4             	pushl  -0x1c(%ebp)
  800257:	ff 75 e0             	pushl  -0x20(%ebp)
  80025a:	ff 75 dc             	pushl  -0x24(%ebp)
  80025d:	ff 75 d8             	pushl  -0x28(%ebp)
  800260:	e8 2b 09 00 00       	call   800b90 <__udivdi3>
  800265:	83 c4 18             	add    $0x18,%esp
  800268:	52                   	push   %edx
  800269:	50                   	push   %eax
  80026a:	89 f2                	mov    %esi,%edx
  80026c:	89 f8                	mov    %edi,%eax
  80026e:	e8 9e ff ff ff       	call   800211 <printnum>
  800273:	83 c4 20             	add    $0x20,%esp
  800276:	eb 18                	jmp    800290 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800278:	83 ec 08             	sub    $0x8,%esp
  80027b:	56                   	push   %esi
  80027c:	ff 75 18             	pushl  0x18(%ebp)
  80027f:	ff d7                	call   *%edi
  800281:	83 c4 10             	add    $0x10,%esp
  800284:	eb 03                	jmp    800289 <printnum+0x78>
  800286:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800289:	83 eb 01             	sub    $0x1,%ebx
  80028c:	85 db                	test   %ebx,%ebx
  80028e:	7f e8                	jg     800278 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  800290:	83 ec 08             	sub    $0x8,%esp
  800293:	56                   	push   %esi
  800294:	83 ec 04             	sub    $0x4,%esp
  800297:	ff 75 e4             	pushl  -0x1c(%ebp)
  80029a:	ff 75 e0             	pushl  -0x20(%ebp)
  80029d:	ff 75 dc             	pushl  -0x24(%ebp)
  8002a0:	ff 75 d8             	pushl  -0x28(%ebp)
  8002a3:	e8 18 0a 00 00       	call   800cc0 <__umoddi3>
  8002a8:	83 c4 14             	add    $0x14,%esp
  8002ab:	0f be 80 00 0f 80 00 	movsbl 0x800f00(%eax),%eax
  8002b2:	50                   	push   %eax
  8002b3:	ff d7                	call   *%edi
}
  8002b5:	83 c4 10             	add    $0x10,%esp
  8002b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002bb:	5b                   	pop    %ebx
  8002bc:	5e                   	pop    %esi
  8002bd:	5f                   	pop    %edi
  8002be:	5d                   	pop    %ebp
  8002bf:	c3                   	ret    

008002c0 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002c0:	55                   	push   %ebp
  8002c1:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002c3:	83 fa 01             	cmp    $0x1,%edx
  8002c6:	7e 0e                	jle    8002d6 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002c8:	8b 10                	mov    (%eax),%edx
  8002ca:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002cd:	89 08                	mov    %ecx,(%eax)
  8002cf:	8b 02                	mov    (%edx),%eax
  8002d1:	8b 52 04             	mov    0x4(%edx),%edx
  8002d4:	eb 22                	jmp    8002f8 <getuint+0x38>
	else if (lflag)
  8002d6:	85 d2                	test   %edx,%edx
  8002d8:	74 10                	je     8002ea <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002da:	8b 10                	mov    (%eax),%edx
  8002dc:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002df:	89 08                	mov    %ecx,(%eax)
  8002e1:	8b 02                	mov    (%edx),%eax
  8002e3:	ba 00 00 00 00       	mov    $0x0,%edx
  8002e8:	eb 0e                	jmp    8002f8 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002ea:	8b 10                	mov    (%eax),%edx
  8002ec:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ef:	89 08                	mov    %ecx,(%eax)
  8002f1:	8b 02                	mov    (%edx),%eax
  8002f3:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002f8:	5d                   	pop    %ebp
  8002f9:	c3                   	ret    

008002fa <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  8002fa:	55                   	push   %ebp
  8002fb:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002fd:	83 fa 01             	cmp    $0x1,%edx
  800300:	7e 0e                	jle    800310 <getint+0x16>
		return va_arg(*ap, long long);
  800302:	8b 10                	mov    (%eax),%edx
  800304:	8d 4a 08             	lea    0x8(%edx),%ecx
  800307:	89 08                	mov    %ecx,(%eax)
  800309:	8b 02                	mov    (%edx),%eax
  80030b:	8b 52 04             	mov    0x4(%edx),%edx
  80030e:	eb 1a                	jmp    80032a <getint+0x30>
	else if (lflag)
  800310:	85 d2                	test   %edx,%edx
  800312:	74 0c                	je     800320 <getint+0x26>
		return va_arg(*ap, long);
  800314:	8b 10                	mov    (%eax),%edx
  800316:	8d 4a 04             	lea    0x4(%edx),%ecx
  800319:	89 08                	mov    %ecx,(%eax)
  80031b:	8b 02                	mov    (%edx),%eax
  80031d:	99                   	cltd   
  80031e:	eb 0a                	jmp    80032a <getint+0x30>
	else
		return va_arg(*ap, int);
  800320:	8b 10                	mov    (%eax),%edx
  800322:	8d 4a 04             	lea    0x4(%edx),%ecx
  800325:	89 08                	mov    %ecx,(%eax)
  800327:	8b 02                	mov    (%edx),%eax
  800329:	99                   	cltd   
}
  80032a:	5d                   	pop    %ebp
  80032b:	c3                   	ret    

0080032c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  80032c:	55                   	push   %ebp
  80032d:	89 e5                	mov    %esp,%ebp
  80032f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800332:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800336:	8b 10                	mov    (%eax),%edx
  800338:	3b 50 04             	cmp    0x4(%eax),%edx
  80033b:	73 0a                	jae    800347 <sprintputch+0x1b>
		*b->buf++ = ch;
  80033d:	8d 4a 01             	lea    0x1(%edx),%ecx
  800340:	89 08                	mov    %ecx,(%eax)
  800342:	8b 45 08             	mov    0x8(%ebp),%eax
  800345:	88 02                	mov    %al,(%edx)
}
  800347:	5d                   	pop    %ebp
  800348:	c3                   	ret    

00800349 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800349:	55                   	push   %ebp
  80034a:	89 e5                	mov    %esp,%ebp
  80034c:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80034f:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800352:	50                   	push   %eax
  800353:	ff 75 10             	pushl  0x10(%ebp)
  800356:	ff 75 0c             	pushl  0xc(%ebp)
  800359:	ff 75 08             	pushl  0x8(%ebp)
  80035c:	e8 05 00 00 00       	call   800366 <vprintfmt>
	va_end(ap);
}
  800361:	83 c4 10             	add    $0x10,%esp
  800364:	c9                   	leave  
  800365:	c3                   	ret    

00800366 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800366:	55                   	push   %ebp
  800367:	89 e5                	mov    %esp,%ebp
  800369:	57                   	push   %edi
  80036a:	56                   	push   %esi
  80036b:	53                   	push   %ebx
  80036c:	83 ec 2c             	sub    $0x2c,%esp
  80036f:	8b 75 08             	mov    0x8(%ebp),%esi
  800372:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800375:	8b 7d 10             	mov    0x10(%ebp),%edi
  800378:	eb 12                	jmp    80038c <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80037a:	85 c0                	test   %eax,%eax
  80037c:	0f 84 44 03 00 00    	je     8006c6 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  800382:	83 ec 08             	sub    $0x8,%esp
  800385:	53                   	push   %ebx
  800386:	50                   	push   %eax
  800387:	ff d6                	call   *%esi
  800389:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  80038c:	83 c7 01             	add    $0x1,%edi
  80038f:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  800393:	83 f8 25             	cmp    $0x25,%eax
  800396:	75 e2                	jne    80037a <vprintfmt+0x14>
  800398:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  80039c:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003a3:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003aa:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003b1:	ba 00 00 00 00       	mov    $0x0,%edx
  8003b6:	eb 07                	jmp    8003bf <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003bb:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bf:	8d 47 01             	lea    0x1(%edi),%eax
  8003c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003c5:	0f b6 07             	movzbl (%edi),%eax
  8003c8:	0f b6 c8             	movzbl %al,%ecx
  8003cb:	83 e8 23             	sub    $0x23,%eax
  8003ce:	3c 55                	cmp    $0x55,%al
  8003d0:	0f 87 d5 02 00 00    	ja     8006ab <vprintfmt+0x345>
  8003d6:	0f b6 c0             	movzbl %al,%eax
  8003d9:	ff 24 85 90 0f 80 00 	jmp    *0x800f90(,%eax,4)
  8003e0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003e3:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003e7:	eb d6                	jmp    8003bf <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003e9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8003ec:	b8 00 00 00 00       	mov    $0x0,%eax
  8003f1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003f4:	8d 04 80             	lea    (%eax,%eax,4),%eax
  8003f7:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  8003fb:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  8003fe:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800401:	83 fa 09             	cmp    $0x9,%edx
  800404:	77 39                	ja     80043f <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800406:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800409:	eb e9                	jmp    8003f4 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80040b:	8b 45 14             	mov    0x14(%ebp),%eax
  80040e:	8d 48 04             	lea    0x4(%eax),%ecx
  800411:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800414:	8b 00                	mov    (%eax),%eax
  800416:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800419:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  80041c:	eb 27                	jmp    800445 <vprintfmt+0xdf>
  80041e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800421:	85 c0                	test   %eax,%eax
  800423:	b9 00 00 00 00       	mov    $0x0,%ecx
  800428:	0f 49 c8             	cmovns %eax,%ecx
  80042b:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800431:	eb 8c                	jmp    8003bf <vprintfmt+0x59>
  800433:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800436:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  80043d:	eb 80                	jmp    8003bf <vprintfmt+0x59>
  80043f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800442:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800445:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800449:	0f 89 70 ff ff ff    	jns    8003bf <vprintfmt+0x59>
				width = precision, precision = -1;
  80044f:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800452:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800455:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  80045c:	e9 5e ff ff ff       	jmp    8003bf <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800461:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800464:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  800467:	e9 53 ff ff ff       	jmp    8003bf <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  80046c:	8b 45 14             	mov    0x14(%ebp),%eax
  80046f:	8d 50 04             	lea    0x4(%eax),%edx
  800472:	89 55 14             	mov    %edx,0x14(%ebp)
  800475:	83 ec 08             	sub    $0x8,%esp
  800478:	53                   	push   %ebx
  800479:	ff 30                	pushl  (%eax)
  80047b:	ff d6                	call   *%esi
			break;
  80047d:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800480:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800483:	e9 04 ff ff ff       	jmp    80038c <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  800488:	8b 45 14             	mov    0x14(%ebp),%eax
  80048b:	8d 50 04             	lea    0x4(%eax),%edx
  80048e:	89 55 14             	mov    %edx,0x14(%ebp)
  800491:	8b 00                	mov    (%eax),%eax
  800493:	99                   	cltd   
  800494:	31 d0                	xor    %edx,%eax
  800496:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800498:	83 f8 06             	cmp    $0x6,%eax
  80049b:	7f 0b                	jg     8004a8 <vprintfmt+0x142>
  80049d:	8b 14 85 e8 10 80 00 	mov    0x8010e8(,%eax,4),%edx
  8004a4:	85 d2                	test   %edx,%edx
  8004a6:	75 18                	jne    8004c0 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004a8:	50                   	push   %eax
  8004a9:	68 18 0f 80 00       	push   $0x800f18
  8004ae:	53                   	push   %ebx
  8004af:	56                   	push   %esi
  8004b0:	e8 94 fe ff ff       	call   800349 <printfmt>
  8004b5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004bb:	e9 cc fe ff ff       	jmp    80038c <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004c0:	52                   	push   %edx
  8004c1:	68 21 0f 80 00       	push   $0x800f21
  8004c6:	53                   	push   %ebx
  8004c7:	56                   	push   %esi
  8004c8:	e8 7c fe ff ff       	call   800349 <printfmt>
  8004cd:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004d3:	e9 b4 fe ff ff       	jmp    80038c <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8004db:	8d 50 04             	lea    0x4(%eax),%edx
  8004de:	89 55 14             	mov    %edx,0x14(%ebp)
  8004e1:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004e3:	85 ff                	test   %edi,%edi
  8004e5:	b8 11 0f 80 00       	mov    $0x800f11,%eax
  8004ea:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  8004ed:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004f1:	0f 8e 94 00 00 00    	jle    80058b <vprintfmt+0x225>
  8004f7:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  8004fb:	0f 84 98 00 00 00    	je     800599 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800501:	83 ec 08             	sub    $0x8,%esp
  800504:	ff 75 d0             	pushl  -0x30(%ebp)
  800507:	57                   	push   %edi
  800508:	e8 41 02 00 00       	call   80074e <strnlen>
  80050d:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800510:	29 c1                	sub    %eax,%ecx
  800512:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800515:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800518:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  80051c:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80051f:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800522:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800524:	eb 0f                	jmp    800535 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800526:	83 ec 08             	sub    $0x8,%esp
  800529:	53                   	push   %ebx
  80052a:	ff 75 e0             	pushl  -0x20(%ebp)
  80052d:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80052f:	83 ef 01             	sub    $0x1,%edi
  800532:	83 c4 10             	add    $0x10,%esp
  800535:	85 ff                	test   %edi,%edi
  800537:	7f ed                	jg     800526 <vprintfmt+0x1c0>
  800539:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  80053c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80053f:	85 c9                	test   %ecx,%ecx
  800541:	b8 00 00 00 00       	mov    $0x0,%eax
  800546:	0f 49 c1             	cmovns %ecx,%eax
  800549:	29 c1                	sub    %eax,%ecx
  80054b:	89 75 08             	mov    %esi,0x8(%ebp)
  80054e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800551:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800554:	89 cb                	mov    %ecx,%ebx
  800556:	eb 4d                	jmp    8005a5 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800558:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  80055c:	74 1b                	je     800579 <vprintfmt+0x213>
  80055e:	0f be c0             	movsbl %al,%eax
  800561:	83 e8 20             	sub    $0x20,%eax
  800564:	83 f8 5e             	cmp    $0x5e,%eax
  800567:	76 10                	jbe    800579 <vprintfmt+0x213>
					putch('?', putdat);
  800569:	83 ec 08             	sub    $0x8,%esp
  80056c:	ff 75 0c             	pushl  0xc(%ebp)
  80056f:	6a 3f                	push   $0x3f
  800571:	ff 55 08             	call   *0x8(%ebp)
  800574:	83 c4 10             	add    $0x10,%esp
  800577:	eb 0d                	jmp    800586 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  800579:	83 ec 08             	sub    $0x8,%esp
  80057c:	ff 75 0c             	pushl  0xc(%ebp)
  80057f:	52                   	push   %edx
  800580:	ff 55 08             	call   *0x8(%ebp)
  800583:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800586:	83 eb 01             	sub    $0x1,%ebx
  800589:	eb 1a                	jmp    8005a5 <vprintfmt+0x23f>
  80058b:	89 75 08             	mov    %esi,0x8(%ebp)
  80058e:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800591:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800594:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  800597:	eb 0c                	jmp    8005a5 <vprintfmt+0x23f>
  800599:	89 75 08             	mov    %esi,0x8(%ebp)
  80059c:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80059f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005a2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005a5:	83 c7 01             	add    $0x1,%edi
  8005a8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005ac:	0f be d0             	movsbl %al,%edx
  8005af:	85 d2                	test   %edx,%edx
  8005b1:	74 23                	je     8005d6 <vprintfmt+0x270>
  8005b3:	85 f6                	test   %esi,%esi
  8005b5:	78 a1                	js     800558 <vprintfmt+0x1f2>
  8005b7:	83 ee 01             	sub    $0x1,%esi
  8005ba:	79 9c                	jns    800558 <vprintfmt+0x1f2>
  8005bc:	89 df                	mov    %ebx,%edi
  8005be:	8b 75 08             	mov    0x8(%ebp),%esi
  8005c1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005c4:	eb 18                	jmp    8005de <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005c6:	83 ec 08             	sub    $0x8,%esp
  8005c9:	53                   	push   %ebx
  8005ca:	6a 20                	push   $0x20
  8005cc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005ce:	83 ef 01             	sub    $0x1,%edi
  8005d1:	83 c4 10             	add    $0x10,%esp
  8005d4:	eb 08                	jmp    8005de <vprintfmt+0x278>
  8005d6:	89 df                	mov    %ebx,%edi
  8005d8:	8b 75 08             	mov    0x8(%ebp),%esi
  8005db:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005de:	85 ff                	test   %edi,%edi
  8005e0:	7f e4                	jg     8005c6 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005e5:	e9 a2 fd ff ff       	jmp    80038c <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ea:	8d 45 14             	lea    0x14(%ebp),%eax
  8005ed:	e8 08 fd ff ff       	call   8002fa <getint>
  8005f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8005f5:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005f8:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005fd:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800601:	79 74                	jns    800677 <vprintfmt+0x311>
				putch('-', putdat);
  800603:	83 ec 08             	sub    $0x8,%esp
  800606:	53                   	push   %ebx
  800607:	6a 2d                	push   $0x2d
  800609:	ff d6                	call   *%esi
				num = -(long long) num;
  80060b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80060e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800611:	f7 d8                	neg    %eax
  800613:	83 d2 00             	adc    $0x0,%edx
  800616:	f7 da                	neg    %edx
  800618:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80061b:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800620:	eb 55                	jmp    800677 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800622:	8d 45 14             	lea    0x14(%ebp),%eax
  800625:	e8 96 fc ff ff       	call   8002c0 <getuint>
			base = 10;
  80062a:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80062f:	eb 46                	jmp    800677 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800631:	8d 45 14             	lea    0x14(%ebp),%eax
  800634:	e8 87 fc ff ff       	call   8002c0 <getuint>
			base = 8;
  800639:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80063e:	eb 37                	jmp    800677 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800640:	83 ec 08             	sub    $0x8,%esp
  800643:	53                   	push   %ebx
  800644:	6a 30                	push   $0x30
  800646:	ff d6                	call   *%esi
			putch('x', putdat);
  800648:	83 c4 08             	add    $0x8,%esp
  80064b:	53                   	push   %ebx
  80064c:	6a 78                	push   $0x78
  80064e:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800650:	8b 45 14             	mov    0x14(%ebp),%eax
  800653:	8d 50 04             	lea    0x4(%eax),%edx
  800656:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800659:	8b 00                	mov    (%eax),%eax
  80065b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800660:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800663:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800668:	eb 0d                	jmp    800677 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80066a:	8d 45 14             	lea    0x14(%ebp),%eax
  80066d:	e8 4e fc ff ff       	call   8002c0 <getuint>
			base = 16;
  800672:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800677:	83 ec 0c             	sub    $0xc,%esp
  80067a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  80067e:	57                   	push   %edi
  80067f:	ff 75 e0             	pushl  -0x20(%ebp)
  800682:	51                   	push   %ecx
  800683:	52                   	push   %edx
  800684:	50                   	push   %eax
  800685:	89 da                	mov    %ebx,%edx
  800687:	89 f0                	mov    %esi,%eax
  800689:	e8 83 fb ff ff       	call   800211 <printnum>
			break;
  80068e:	83 c4 20             	add    $0x20,%esp
  800691:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800694:	e9 f3 fc ff ff       	jmp    80038c <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  800699:	83 ec 08             	sub    $0x8,%esp
  80069c:	53                   	push   %ebx
  80069d:	51                   	push   %ecx
  80069e:	ff d6                	call   *%esi
			break;
  8006a0:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006a3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006a6:	e9 e1 fc ff ff       	jmp    80038c <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006ab:	83 ec 08             	sub    $0x8,%esp
  8006ae:	53                   	push   %ebx
  8006af:	6a 25                	push   $0x25
  8006b1:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006b3:	83 c4 10             	add    $0x10,%esp
  8006b6:	eb 03                	jmp    8006bb <vprintfmt+0x355>
  8006b8:	83 ef 01             	sub    $0x1,%edi
  8006bb:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006bf:	75 f7                	jne    8006b8 <vprintfmt+0x352>
  8006c1:	e9 c6 fc ff ff       	jmp    80038c <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006c9:	5b                   	pop    %ebx
  8006ca:	5e                   	pop    %esi
  8006cb:	5f                   	pop    %edi
  8006cc:	5d                   	pop    %ebp
  8006cd:	c3                   	ret    

008006ce <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006ce:	55                   	push   %ebp
  8006cf:	89 e5                	mov    %esp,%ebp
  8006d1:	83 ec 18             	sub    $0x18,%esp
  8006d4:	8b 45 08             	mov    0x8(%ebp),%eax
  8006d7:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006da:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006dd:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006e1:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006e4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006eb:	85 c0                	test   %eax,%eax
  8006ed:	74 26                	je     800715 <vsnprintf+0x47>
  8006ef:	85 d2                	test   %edx,%edx
  8006f1:	7e 22                	jle    800715 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006f3:	ff 75 14             	pushl  0x14(%ebp)
  8006f6:	ff 75 10             	pushl  0x10(%ebp)
  8006f9:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006fc:	50                   	push   %eax
  8006fd:	68 2c 03 80 00       	push   $0x80032c
  800702:	e8 5f fc ff ff       	call   800366 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800707:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80070a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80070d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800710:	83 c4 10             	add    $0x10,%esp
  800713:	eb 05                	jmp    80071a <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800715:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80071a:	c9                   	leave  
  80071b:	c3                   	ret    

0080071c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80071c:	55                   	push   %ebp
  80071d:	89 e5                	mov    %esp,%ebp
  80071f:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800722:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800725:	50                   	push   %eax
  800726:	ff 75 10             	pushl  0x10(%ebp)
  800729:	ff 75 0c             	pushl  0xc(%ebp)
  80072c:	ff 75 08             	pushl  0x8(%ebp)
  80072f:	e8 9a ff ff ff       	call   8006ce <vsnprintf>
	va_end(ap);

	return rc;
}
  800734:	c9                   	leave  
  800735:	c3                   	ret    

00800736 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800736:	55                   	push   %ebp
  800737:	89 e5                	mov    %esp,%ebp
  800739:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  80073c:	b8 00 00 00 00       	mov    $0x0,%eax
  800741:	eb 03                	jmp    800746 <strlen+0x10>
		n++;
  800743:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800746:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80074a:	75 f7                	jne    800743 <strlen+0xd>
		n++;
	return n;
}
  80074c:	5d                   	pop    %ebp
  80074d:	c3                   	ret    

0080074e <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80074e:	55                   	push   %ebp
  80074f:	89 e5                	mov    %esp,%ebp
  800751:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800754:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800757:	ba 00 00 00 00       	mov    $0x0,%edx
  80075c:	eb 03                	jmp    800761 <strnlen+0x13>
		n++;
  80075e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800761:	39 c2                	cmp    %eax,%edx
  800763:	74 08                	je     80076d <strnlen+0x1f>
  800765:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  800769:	75 f3                	jne    80075e <strnlen+0x10>
  80076b:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  80076d:	5d                   	pop    %ebp
  80076e:	c3                   	ret    

0080076f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  80076f:	55                   	push   %ebp
  800770:	89 e5                	mov    %esp,%ebp
  800772:	53                   	push   %ebx
  800773:	8b 45 08             	mov    0x8(%ebp),%eax
  800776:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800779:	89 c2                	mov    %eax,%edx
  80077b:	83 c2 01             	add    $0x1,%edx
  80077e:	83 c1 01             	add    $0x1,%ecx
  800781:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800785:	88 5a ff             	mov    %bl,-0x1(%edx)
  800788:	84 db                	test   %bl,%bl
  80078a:	75 ef                	jne    80077b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  80078c:	5b                   	pop    %ebx
  80078d:	5d                   	pop    %ebp
  80078e:	c3                   	ret    

0080078f <strcat>:

char *
strcat(char *dst, const char *src)
{
  80078f:	55                   	push   %ebp
  800790:	89 e5                	mov    %esp,%ebp
  800792:	53                   	push   %ebx
  800793:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800796:	53                   	push   %ebx
  800797:	e8 9a ff ff ff       	call   800736 <strlen>
  80079c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  80079f:	ff 75 0c             	pushl  0xc(%ebp)
  8007a2:	01 d8                	add    %ebx,%eax
  8007a4:	50                   	push   %eax
  8007a5:	e8 c5 ff ff ff       	call   80076f <strcpy>
	return dst;
}
  8007aa:	89 d8                	mov    %ebx,%eax
  8007ac:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007af:	c9                   	leave  
  8007b0:	c3                   	ret    

008007b1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007b1:	55                   	push   %ebp
  8007b2:	89 e5                	mov    %esp,%ebp
  8007b4:	56                   	push   %esi
  8007b5:	53                   	push   %ebx
  8007b6:	8b 75 08             	mov    0x8(%ebp),%esi
  8007b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007bc:	89 f3                	mov    %esi,%ebx
  8007be:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007c1:	89 f2                	mov    %esi,%edx
  8007c3:	eb 0f                	jmp    8007d4 <strncpy+0x23>
		*dst++ = *src;
  8007c5:	83 c2 01             	add    $0x1,%edx
  8007c8:	0f b6 01             	movzbl (%ecx),%eax
  8007cb:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ce:	80 39 01             	cmpb   $0x1,(%ecx)
  8007d1:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007d4:	39 da                	cmp    %ebx,%edx
  8007d6:	75 ed                	jne    8007c5 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007d8:	89 f0                	mov    %esi,%eax
  8007da:	5b                   	pop    %ebx
  8007db:	5e                   	pop    %esi
  8007dc:	5d                   	pop    %ebp
  8007dd:	c3                   	ret    

008007de <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007de:	55                   	push   %ebp
  8007df:	89 e5                	mov    %esp,%ebp
  8007e1:	56                   	push   %esi
  8007e2:	53                   	push   %ebx
  8007e3:	8b 75 08             	mov    0x8(%ebp),%esi
  8007e6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007e9:	8b 55 10             	mov    0x10(%ebp),%edx
  8007ec:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8007ee:	85 d2                	test   %edx,%edx
  8007f0:	74 21                	je     800813 <strlcpy+0x35>
  8007f2:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  8007f6:	89 f2                	mov    %esi,%edx
  8007f8:	eb 09                	jmp    800803 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8007fa:	83 c2 01             	add    $0x1,%edx
  8007fd:	83 c1 01             	add    $0x1,%ecx
  800800:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800803:	39 c2                	cmp    %eax,%edx
  800805:	74 09                	je     800810 <strlcpy+0x32>
  800807:	0f b6 19             	movzbl (%ecx),%ebx
  80080a:	84 db                	test   %bl,%bl
  80080c:	75 ec                	jne    8007fa <strlcpy+0x1c>
  80080e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800810:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800813:	29 f0                	sub    %esi,%eax
}
  800815:	5b                   	pop    %ebx
  800816:	5e                   	pop    %esi
  800817:	5d                   	pop    %ebp
  800818:	c3                   	ret    

00800819 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800819:	55                   	push   %ebp
  80081a:	89 e5                	mov    %esp,%ebp
  80081c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80081f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800822:	eb 06                	jmp    80082a <strcmp+0x11>
		p++, q++;
  800824:	83 c1 01             	add    $0x1,%ecx
  800827:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80082a:	0f b6 01             	movzbl (%ecx),%eax
  80082d:	84 c0                	test   %al,%al
  80082f:	74 04                	je     800835 <strcmp+0x1c>
  800831:	3a 02                	cmp    (%edx),%al
  800833:	74 ef                	je     800824 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800835:	0f b6 c0             	movzbl %al,%eax
  800838:	0f b6 12             	movzbl (%edx),%edx
  80083b:	29 d0                	sub    %edx,%eax
}
  80083d:	5d                   	pop    %ebp
  80083e:	c3                   	ret    

0080083f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80083f:	55                   	push   %ebp
  800840:	89 e5                	mov    %esp,%ebp
  800842:	53                   	push   %ebx
  800843:	8b 45 08             	mov    0x8(%ebp),%eax
  800846:	8b 55 0c             	mov    0xc(%ebp),%edx
  800849:	89 c3                	mov    %eax,%ebx
  80084b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80084e:	eb 06                	jmp    800856 <strncmp+0x17>
		n--, p++, q++;
  800850:	83 c0 01             	add    $0x1,%eax
  800853:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800856:	39 d8                	cmp    %ebx,%eax
  800858:	74 15                	je     80086f <strncmp+0x30>
  80085a:	0f b6 08             	movzbl (%eax),%ecx
  80085d:	84 c9                	test   %cl,%cl
  80085f:	74 04                	je     800865 <strncmp+0x26>
  800861:	3a 0a                	cmp    (%edx),%cl
  800863:	74 eb                	je     800850 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800865:	0f b6 00             	movzbl (%eax),%eax
  800868:	0f b6 12             	movzbl (%edx),%edx
  80086b:	29 d0                	sub    %edx,%eax
  80086d:	eb 05                	jmp    800874 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  80086f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800874:	5b                   	pop    %ebx
  800875:	5d                   	pop    %ebp
  800876:	c3                   	ret    

00800877 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800877:	55                   	push   %ebp
  800878:	89 e5                	mov    %esp,%ebp
  80087a:	8b 45 08             	mov    0x8(%ebp),%eax
  80087d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800881:	eb 07                	jmp    80088a <strchr+0x13>
		if (*s == c)
  800883:	38 ca                	cmp    %cl,%dl
  800885:	74 0f                	je     800896 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800887:	83 c0 01             	add    $0x1,%eax
  80088a:	0f b6 10             	movzbl (%eax),%edx
  80088d:	84 d2                	test   %dl,%dl
  80088f:	75 f2                	jne    800883 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800891:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800896:	5d                   	pop    %ebp
  800897:	c3                   	ret    

00800898 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800898:	55                   	push   %ebp
  800899:	89 e5                	mov    %esp,%ebp
  80089b:	8b 45 08             	mov    0x8(%ebp),%eax
  80089e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a2:	eb 03                	jmp    8008a7 <strfind+0xf>
  8008a4:	83 c0 01             	add    $0x1,%eax
  8008a7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008aa:	38 ca                	cmp    %cl,%dl
  8008ac:	74 04                	je     8008b2 <strfind+0x1a>
  8008ae:	84 d2                	test   %dl,%dl
  8008b0:	75 f2                	jne    8008a4 <strfind+0xc>
			break;
	return (char *) s;
}
  8008b2:	5d                   	pop    %ebp
  8008b3:	c3                   	ret    

008008b4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008b4:	55                   	push   %ebp
  8008b5:	89 e5                	mov    %esp,%ebp
  8008b7:	57                   	push   %edi
  8008b8:	56                   	push   %esi
  8008b9:	53                   	push   %ebx
  8008ba:	8b 55 08             	mov    0x8(%ebp),%edx
  8008bd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8008c0:	85 c9                	test   %ecx,%ecx
  8008c2:	74 37                	je     8008fb <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008c4:	f6 c2 03             	test   $0x3,%dl
  8008c7:	75 2a                	jne    8008f3 <memset+0x3f>
  8008c9:	f6 c1 03             	test   $0x3,%cl
  8008cc:	75 25                	jne    8008f3 <memset+0x3f>
		c &= 0xFF;
  8008ce:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008d2:	89 df                	mov    %ebx,%edi
  8008d4:	c1 e7 08             	shl    $0x8,%edi
  8008d7:	89 de                	mov    %ebx,%esi
  8008d9:	c1 e6 18             	shl    $0x18,%esi
  8008dc:	89 d8                	mov    %ebx,%eax
  8008de:	c1 e0 10             	shl    $0x10,%eax
  8008e1:	09 f0                	or     %esi,%eax
  8008e3:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  8008e5:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8008e8:	89 f8                	mov    %edi,%eax
  8008ea:	09 d8                	or     %ebx,%eax
  8008ec:	89 d7                	mov    %edx,%edi
  8008ee:	fc                   	cld    
  8008ef:	f3 ab                	rep stos %eax,%es:(%edi)
  8008f1:	eb 08                	jmp    8008fb <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8008f3:	89 d7                	mov    %edx,%edi
  8008f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8008f8:	fc                   	cld    
  8008f9:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  8008fb:	89 d0                	mov    %edx,%eax
  8008fd:	5b                   	pop    %ebx
  8008fe:	5e                   	pop    %esi
  8008ff:	5f                   	pop    %edi
  800900:	5d                   	pop    %ebp
  800901:	c3                   	ret    

00800902 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800902:	55                   	push   %ebp
  800903:	89 e5                	mov    %esp,%ebp
  800905:	57                   	push   %edi
  800906:	56                   	push   %esi
  800907:	8b 45 08             	mov    0x8(%ebp),%eax
  80090a:	8b 75 0c             	mov    0xc(%ebp),%esi
  80090d:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800910:	39 c6                	cmp    %eax,%esi
  800912:	73 35                	jae    800949 <memmove+0x47>
  800914:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800917:	39 d0                	cmp    %edx,%eax
  800919:	73 2e                	jae    800949 <memmove+0x47>
		s += n;
		d += n;
  80091b:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80091e:	89 d6                	mov    %edx,%esi
  800920:	09 fe                	or     %edi,%esi
  800922:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800928:	75 13                	jne    80093d <memmove+0x3b>
  80092a:	f6 c1 03             	test   $0x3,%cl
  80092d:	75 0e                	jne    80093d <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80092f:	83 ef 04             	sub    $0x4,%edi
  800932:	8d 72 fc             	lea    -0x4(%edx),%esi
  800935:	c1 e9 02             	shr    $0x2,%ecx
  800938:	fd                   	std    
  800939:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80093b:	eb 09                	jmp    800946 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  80093d:	83 ef 01             	sub    $0x1,%edi
  800940:	8d 72 ff             	lea    -0x1(%edx),%esi
  800943:	fd                   	std    
  800944:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800946:	fc                   	cld    
  800947:	eb 1d                	jmp    800966 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800949:	89 f2                	mov    %esi,%edx
  80094b:	09 c2                	or     %eax,%edx
  80094d:	f6 c2 03             	test   $0x3,%dl
  800950:	75 0f                	jne    800961 <memmove+0x5f>
  800952:	f6 c1 03             	test   $0x3,%cl
  800955:	75 0a                	jne    800961 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800957:	c1 e9 02             	shr    $0x2,%ecx
  80095a:	89 c7                	mov    %eax,%edi
  80095c:	fc                   	cld    
  80095d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095f:	eb 05                	jmp    800966 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800961:	89 c7                	mov    %eax,%edi
  800963:	fc                   	cld    
  800964:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800966:	5e                   	pop    %esi
  800967:	5f                   	pop    %edi
  800968:	5d                   	pop    %ebp
  800969:	c3                   	ret    

0080096a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80096a:	55                   	push   %ebp
  80096b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  80096d:	ff 75 10             	pushl  0x10(%ebp)
  800970:	ff 75 0c             	pushl  0xc(%ebp)
  800973:	ff 75 08             	pushl  0x8(%ebp)
  800976:	e8 87 ff ff ff       	call   800902 <memmove>
}
  80097b:	c9                   	leave  
  80097c:	c3                   	ret    

0080097d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80097d:	55                   	push   %ebp
  80097e:	89 e5                	mov    %esp,%ebp
  800980:	56                   	push   %esi
  800981:	53                   	push   %ebx
  800982:	8b 45 08             	mov    0x8(%ebp),%eax
  800985:	8b 55 0c             	mov    0xc(%ebp),%edx
  800988:	89 c6                	mov    %eax,%esi
  80098a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  80098d:	eb 1a                	jmp    8009a9 <memcmp+0x2c>
		if (*s1 != *s2)
  80098f:	0f b6 08             	movzbl (%eax),%ecx
  800992:	0f b6 1a             	movzbl (%edx),%ebx
  800995:	38 d9                	cmp    %bl,%cl
  800997:	74 0a                	je     8009a3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800999:	0f b6 c1             	movzbl %cl,%eax
  80099c:	0f b6 db             	movzbl %bl,%ebx
  80099f:	29 d8                	sub    %ebx,%eax
  8009a1:	eb 0f                	jmp    8009b2 <memcmp+0x35>
		s1++, s2++;
  8009a3:	83 c0 01             	add    $0x1,%eax
  8009a6:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009a9:	39 f0                	cmp    %esi,%eax
  8009ab:	75 e2                	jne    80098f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009b2:	5b                   	pop    %ebx
  8009b3:	5e                   	pop    %esi
  8009b4:	5d                   	pop    %ebp
  8009b5:	c3                   	ret    

008009b6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009b6:	55                   	push   %ebp
  8009b7:	89 e5                	mov    %esp,%ebp
  8009b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009bf:	89 c2                	mov    %eax,%edx
  8009c1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009c4:	eb 07                	jmp    8009cd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009c6:	38 08                	cmp    %cl,(%eax)
  8009c8:	74 07                	je     8009d1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ca:	83 c0 01             	add    $0x1,%eax
  8009cd:	39 d0                	cmp    %edx,%eax
  8009cf:	72 f5                	jb     8009c6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009d1:	5d                   	pop    %ebp
  8009d2:	c3                   	ret    

008009d3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009d3:	55                   	push   %ebp
  8009d4:	89 e5                	mov    %esp,%ebp
  8009d6:	57                   	push   %edi
  8009d7:	56                   	push   %esi
  8009d8:	53                   	push   %ebx
  8009d9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009dc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009df:	eb 03                	jmp    8009e4 <strtol+0x11>
		s++;
  8009e1:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009e4:	0f b6 01             	movzbl (%ecx),%eax
  8009e7:	3c 20                	cmp    $0x20,%al
  8009e9:	74 f6                	je     8009e1 <strtol+0xe>
  8009eb:	3c 09                	cmp    $0x9,%al
  8009ed:	74 f2                	je     8009e1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  8009ef:	3c 2b                	cmp    $0x2b,%al
  8009f1:	75 0a                	jne    8009fd <strtol+0x2a>
		s++;
  8009f3:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  8009f6:	bf 00 00 00 00       	mov    $0x0,%edi
  8009fb:	eb 11                	jmp    800a0e <strtol+0x3b>
  8009fd:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a02:	3c 2d                	cmp    $0x2d,%al
  800a04:	75 08                	jne    800a0e <strtol+0x3b>
		s++, neg = 1;
  800a06:	83 c1 01             	add    $0x1,%ecx
  800a09:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a0e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a14:	75 15                	jne    800a2b <strtol+0x58>
  800a16:	80 39 30             	cmpb   $0x30,(%ecx)
  800a19:	75 10                	jne    800a2b <strtol+0x58>
  800a1b:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a1f:	75 7c                	jne    800a9d <strtol+0xca>
		s += 2, base = 16;
  800a21:	83 c1 02             	add    $0x2,%ecx
  800a24:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a29:	eb 16                	jmp    800a41 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a2b:	85 db                	test   %ebx,%ebx
  800a2d:	75 12                	jne    800a41 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a2f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a34:	80 39 30             	cmpb   $0x30,(%ecx)
  800a37:	75 08                	jne    800a41 <strtol+0x6e>
		s++, base = 8;
  800a39:	83 c1 01             	add    $0x1,%ecx
  800a3c:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a41:	b8 00 00 00 00       	mov    $0x0,%eax
  800a46:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a49:	0f b6 11             	movzbl (%ecx),%edx
  800a4c:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a4f:	89 f3                	mov    %esi,%ebx
  800a51:	80 fb 09             	cmp    $0x9,%bl
  800a54:	77 08                	ja     800a5e <strtol+0x8b>
			dig = *s - '0';
  800a56:	0f be d2             	movsbl %dl,%edx
  800a59:	83 ea 30             	sub    $0x30,%edx
  800a5c:	eb 22                	jmp    800a80 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a5e:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a61:	89 f3                	mov    %esi,%ebx
  800a63:	80 fb 19             	cmp    $0x19,%bl
  800a66:	77 08                	ja     800a70 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a68:	0f be d2             	movsbl %dl,%edx
  800a6b:	83 ea 57             	sub    $0x57,%edx
  800a6e:	eb 10                	jmp    800a80 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a70:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a73:	89 f3                	mov    %esi,%ebx
  800a75:	80 fb 19             	cmp    $0x19,%bl
  800a78:	77 16                	ja     800a90 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a7a:	0f be d2             	movsbl %dl,%edx
  800a7d:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a80:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a83:	7d 0b                	jge    800a90 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a85:	83 c1 01             	add    $0x1,%ecx
  800a88:	0f af 45 10          	imul   0x10(%ebp),%eax
  800a8c:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800a8e:	eb b9                	jmp    800a49 <strtol+0x76>

	if (endptr)
  800a90:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800a94:	74 0d                	je     800aa3 <strtol+0xd0>
		*endptr = (char *) s;
  800a96:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a99:	89 0e                	mov    %ecx,(%esi)
  800a9b:	eb 06                	jmp    800aa3 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a9d:	85 db                	test   %ebx,%ebx
  800a9f:	74 98                	je     800a39 <strtol+0x66>
  800aa1:	eb 9e                	jmp    800a41 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800aa3:	89 c2                	mov    %eax,%edx
  800aa5:	f7 da                	neg    %edx
  800aa7:	85 ff                	test   %edi,%edi
  800aa9:	0f 45 c2             	cmovne %edx,%eax
}
  800aac:	5b                   	pop    %ebx
  800aad:	5e                   	pop    %esi
  800aae:	5f                   	pop    %edi
  800aaf:	5d                   	pop    %ebp
  800ab0:	c3                   	ret    

00800ab1 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800ab1:	55                   	push   %ebp
  800ab2:	89 e5                	mov    %esp,%ebp
  800ab4:	57                   	push   %edi
  800ab5:	56                   	push   %esi
  800ab6:	53                   	push   %ebx
  800ab7:	83 ec 1c             	sub    $0x1c,%esp
  800aba:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800abd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800ac0:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ac2:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ac5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800ac8:	8b 7d 10             	mov    0x10(%ebp),%edi
  800acb:	8b 75 14             	mov    0x14(%ebp),%esi
  800ace:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800ad0:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800ad4:	74 1d                	je     800af3 <syscall+0x42>
  800ad6:	85 c0                	test   %eax,%eax
  800ad8:	7e 19                	jle    800af3 <syscall+0x42>
  800ada:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800add:	83 ec 0c             	sub    $0xc,%esp
  800ae0:	50                   	push   %eax
  800ae1:	52                   	push   %edx
  800ae2:	68 04 11 80 00       	push   $0x801104
  800ae7:	6a 23                	push   $0x23
  800ae9:	68 21 11 80 00       	push   $0x801121
  800aee:	e8 31 f6 ff ff       	call   800124 <_panic>

	return ret;
}
  800af3:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800af6:	5b                   	pop    %ebx
  800af7:	5e                   	pop    %esi
  800af8:	5f                   	pop    %edi
  800af9:	5d                   	pop    %ebp
  800afa:	c3                   	ret    

00800afb <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800afb:	55                   	push   %ebp
  800afc:	89 e5                	mov    %esp,%ebp
  800afe:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800b01:	6a 00                	push   $0x0
  800b03:	6a 00                	push   $0x0
  800b05:	6a 00                	push   $0x0
  800b07:	ff 75 0c             	pushl  0xc(%ebp)
  800b0a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b0d:	ba 00 00 00 00       	mov    $0x0,%edx
  800b12:	b8 00 00 00 00       	mov    $0x0,%eax
  800b17:	e8 95 ff ff ff       	call   800ab1 <syscall>
}
  800b1c:	83 c4 10             	add    $0x10,%esp
  800b1f:	c9                   	leave  
  800b20:	c3                   	ret    

00800b21 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b21:	55                   	push   %ebp
  800b22:	89 e5                	mov    %esp,%ebp
  800b24:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800b27:	6a 00                	push   $0x0
  800b29:	6a 00                	push   $0x0
  800b2b:	6a 00                	push   $0x0
  800b2d:	6a 00                	push   $0x0
  800b2f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b34:	ba 00 00 00 00       	mov    $0x0,%edx
  800b39:	b8 01 00 00 00       	mov    $0x1,%eax
  800b3e:	e8 6e ff ff ff       	call   800ab1 <syscall>
}
  800b43:	c9                   	leave  
  800b44:	c3                   	ret    

00800b45 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b45:	55                   	push   %ebp
  800b46:	89 e5                	mov    %esp,%ebp
  800b48:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800b4b:	6a 00                	push   $0x0
  800b4d:	6a 00                	push   $0x0
  800b4f:	6a 00                	push   $0x0
  800b51:	6a 00                	push   $0x0
  800b53:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b56:	ba 01 00 00 00       	mov    $0x1,%edx
  800b5b:	b8 03 00 00 00       	mov    $0x3,%eax
  800b60:	e8 4c ff ff ff       	call   800ab1 <syscall>
}
  800b65:	c9                   	leave  
  800b66:	c3                   	ret    

00800b67 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b67:	55                   	push   %ebp
  800b68:	89 e5                	mov    %esp,%ebp
  800b6a:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800b6d:	6a 00                	push   $0x0
  800b6f:	6a 00                	push   $0x0
  800b71:	6a 00                	push   $0x0
  800b73:	6a 00                	push   $0x0
  800b75:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b7a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b7f:	b8 02 00 00 00       	mov    $0x2,%eax
  800b84:	e8 28 ff ff ff       	call   800ab1 <syscall>
}
  800b89:	c9                   	leave  
  800b8a:	c3                   	ret    
  800b8b:	66 90                	xchg   %ax,%ax
  800b8d:	66 90                	xchg   %ax,%ax
  800b8f:	90                   	nop

00800b90 <__udivdi3>:
  800b90:	55                   	push   %ebp
  800b91:	57                   	push   %edi
  800b92:	56                   	push   %esi
  800b93:	53                   	push   %ebx
  800b94:	83 ec 1c             	sub    $0x1c,%esp
  800b97:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b9b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b9f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800ba3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800ba7:	85 f6                	test   %esi,%esi
  800ba9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800bad:	89 ca                	mov    %ecx,%edx
  800baf:	89 f8                	mov    %edi,%eax
  800bb1:	75 3d                	jne    800bf0 <__udivdi3+0x60>
  800bb3:	39 cf                	cmp    %ecx,%edi
  800bb5:	0f 87 c5 00 00 00    	ja     800c80 <__udivdi3+0xf0>
  800bbb:	85 ff                	test   %edi,%edi
  800bbd:	89 fd                	mov    %edi,%ebp
  800bbf:	75 0b                	jne    800bcc <__udivdi3+0x3c>
  800bc1:	b8 01 00 00 00       	mov    $0x1,%eax
  800bc6:	31 d2                	xor    %edx,%edx
  800bc8:	f7 f7                	div    %edi
  800bca:	89 c5                	mov    %eax,%ebp
  800bcc:	89 c8                	mov    %ecx,%eax
  800bce:	31 d2                	xor    %edx,%edx
  800bd0:	f7 f5                	div    %ebp
  800bd2:	89 c1                	mov    %eax,%ecx
  800bd4:	89 d8                	mov    %ebx,%eax
  800bd6:	89 cf                	mov    %ecx,%edi
  800bd8:	f7 f5                	div    %ebp
  800bda:	89 c3                	mov    %eax,%ebx
  800bdc:	89 d8                	mov    %ebx,%eax
  800bde:	89 fa                	mov    %edi,%edx
  800be0:	83 c4 1c             	add    $0x1c,%esp
  800be3:	5b                   	pop    %ebx
  800be4:	5e                   	pop    %esi
  800be5:	5f                   	pop    %edi
  800be6:	5d                   	pop    %ebp
  800be7:	c3                   	ret    
  800be8:	90                   	nop
  800be9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800bf0:	39 ce                	cmp    %ecx,%esi
  800bf2:	77 74                	ja     800c68 <__udivdi3+0xd8>
  800bf4:	0f bd fe             	bsr    %esi,%edi
  800bf7:	83 f7 1f             	xor    $0x1f,%edi
  800bfa:	0f 84 98 00 00 00    	je     800c98 <__udivdi3+0x108>
  800c00:	bb 20 00 00 00       	mov    $0x20,%ebx
  800c05:	89 f9                	mov    %edi,%ecx
  800c07:	89 c5                	mov    %eax,%ebp
  800c09:	29 fb                	sub    %edi,%ebx
  800c0b:	d3 e6                	shl    %cl,%esi
  800c0d:	89 d9                	mov    %ebx,%ecx
  800c0f:	d3 ed                	shr    %cl,%ebp
  800c11:	89 f9                	mov    %edi,%ecx
  800c13:	d3 e0                	shl    %cl,%eax
  800c15:	09 ee                	or     %ebp,%esi
  800c17:	89 d9                	mov    %ebx,%ecx
  800c19:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800c1d:	89 d5                	mov    %edx,%ebp
  800c1f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800c23:	d3 ed                	shr    %cl,%ebp
  800c25:	89 f9                	mov    %edi,%ecx
  800c27:	d3 e2                	shl    %cl,%edx
  800c29:	89 d9                	mov    %ebx,%ecx
  800c2b:	d3 e8                	shr    %cl,%eax
  800c2d:	09 c2                	or     %eax,%edx
  800c2f:	89 d0                	mov    %edx,%eax
  800c31:	89 ea                	mov    %ebp,%edx
  800c33:	f7 f6                	div    %esi
  800c35:	89 d5                	mov    %edx,%ebp
  800c37:	89 c3                	mov    %eax,%ebx
  800c39:	f7 64 24 0c          	mull   0xc(%esp)
  800c3d:	39 d5                	cmp    %edx,%ebp
  800c3f:	72 10                	jb     800c51 <__udivdi3+0xc1>
  800c41:	8b 74 24 08          	mov    0x8(%esp),%esi
  800c45:	89 f9                	mov    %edi,%ecx
  800c47:	d3 e6                	shl    %cl,%esi
  800c49:	39 c6                	cmp    %eax,%esi
  800c4b:	73 07                	jae    800c54 <__udivdi3+0xc4>
  800c4d:	39 d5                	cmp    %edx,%ebp
  800c4f:	75 03                	jne    800c54 <__udivdi3+0xc4>
  800c51:	83 eb 01             	sub    $0x1,%ebx
  800c54:	31 ff                	xor    %edi,%edi
  800c56:	89 d8                	mov    %ebx,%eax
  800c58:	89 fa                	mov    %edi,%edx
  800c5a:	83 c4 1c             	add    $0x1c,%esp
  800c5d:	5b                   	pop    %ebx
  800c5e:	5e                   	pop    %esi
  800c5f:	5f                   	pop    %edi
  800c60:	5d                   	pop    %ebp
  800c61:	c3                   	ret    
  800c62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c68:	31 ff                	xor    %edi,%edi
  800c6a:	31 db                	xor    %ebx,%ebx
  800c6c:	89 d8                	mov    %ebx,%eax
  800c6e:	89 fa                	mov    %edi,%edx
  800c70:	83 c4 1c             	add    $0x1c,%esp
  800c73:	5b                   	pop    %ebx
  800c74:	5e                   	pop    %esi
  800c75:	5f                   	pop    %edi
  800c76:	5d                   	pop    %ebp
  800c77:	c3                   	ret    
  800c78:	90                   	nop
  800c79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c80:	89 d8                	mov    %ebx,%eax
  800c82:	f7 f7                	div    %edi
  800c84:	31 ff                	xor    %edi,%edi
  800c86:	89 c3                	mov    %eax,%ebx
  800c88:	89 d8                	mov    %ebx,%eax
  800c8a:	89 fa                	mov    %edi,%edx
  800c8c:	83 c4 1c             	add    $0x1c,%esp
  800c8f:	5b                   	pop    %ebx
  800c90:	5e                   	pop    %esi
  800c91:	5f                   	pop    %edi
  800c92:	5d                   	pop    %ebp
  800c93:	c3                   	ret    
  800c94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c98:	39 ce                	cmp    %ecx,%esi
  800c9a:	72 0c                	jb     800ca8 <__udivdi3+0x118>
  800c9c:	31 db                	xor    %ebx,%ebx
  800c9e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800ca2:	0f 87 34 ff ff ff    	ja     800bdc <__udivdi3+0x4c>
  800ca8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800cad:	e9 2a ff ff ff       	jmp    800bdc <__udivdi3+0x4c>
  800cb2:	66 90                	xchg   %ax,%ax
  800cb4:	66 90                	xchg   %ax,%ax
  800cb6:	66 90                	xchg   %ax,%ax
  800cb8:	66 90                	xchg   %ax,%ax
  800cba:	66 90                	xchg   %ax,%ax
  800cbc:	66 90                	xchg   %ax,%ax
  800cbe:	66 90                	xchg   %ax,%ax

00800cc0 <__umoddi3>:
  800cc0:	55                   	push   %ebp
  800cc1:	57                   	push   %edi
  800cc2:	56                   	push   %esi
  800cc3:	53                   	push   %ebx
  800cc4:	83 ec 1c             	sub    $0x1c,%esp
  800cc7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800ccb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800ccf:	8b 74 24 34          	mov    0x34(%esp),%esi
  800cd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cd7:	85 d2                	test   %edx,%edx
  800cd9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800cdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800ce1:	89 f3                	mov    %esi,%ebx
  800ce3:	89 3c 24             	mov    %edi,(%esp)
  800ce6:	89 74 24 04          	mov    %esi,0x4(%esp)
  800cea:	75 1c                	jne    800d08 <__umoddi3+0x48>
  800cec:	39 f7                	cmp    %esi,%edi
  800cee:	76 50                	jbe    800d40 <__umoddi3+0x80>
  800cf0:	89 c8                	mov    %ecx,%eax
  800cf2:	89 f2                	mov    %esi,%edx
  800cf4:	f7 f7                	div    %edi
  800cf6:	89 d0                	mov    %edx,%eax
  800cf8:	31 d2                	xor    %edx,%edx
  800cfa:	83 c4 1c             	add    $0x1c,%esp
  800cfd:	5b                   	pop    %ebx
  800cfe:	5e                   	pop    %esi
  800cff:	5f                   	pop    %edi
  800d00:	5d                   	pop    %ebp
  800d01:	c3                   	ret    
  800d02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d08:	39 f2                	cmp    %esi,%edx
  800d0a:	89 d0                	mov    %edx,%eax
  800d0c:	77 52                	ja     800d60 <__umoddi3+0xa0>
  800d0e:	0f bd ea             	bsr    %edx,%ebp
  800d11:	83 f5 1f             	xor    $0x1f,%ebp
  800d14:	75 5a                	jne    800d70 <__umoddi3+0xb0>
  800d16:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800d1a:	0f 82 e0 00 00 00    	jb     800e00 <__umoddi3+0x140>
  800d20:	39 0c 24             	cmp    %ecx,(%esp)
  800d23:	0f 86 d7 00 00 00    	jbe    800e00 <__umoddi3+0x140>
  800d29:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d2d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800d31:	83 c4 1c             	add    $0x1c,%esp
  800d34:	5b                   	pop    %ebx
  800d35:	5e                   	pop    %esi
  800d36:	5f                   	pop    %edi
  800d37:	5d                   	pop    %ebp
  800d38:	c3                   	ret    
  800d39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d40:	85 ff                	test   %edi,%edi
  800d42:	89 fd                	mov    %edi,%ebp
  800d44:	75 0b                	jne    800d51 <__umoddi3+0x91>
  800d46:	b8 01 00 00 00       	mov    $0x1,%eax
  800d4b:	31 d2                	xor    %edx,%edx
  800d4d:	f7 f7                	div    %edi
  800d4f:	89 c5                	mov    %eax,%ebp
  800d51:	89 f0                	mov    %esi,%eax
  800d53:	31 d2                	xor    %edx,%edx
  800d55:	f7 f5                	div    %ebp
  800d57:	89 c8                	mov    %ecx,%eax
  800d59:	f7 f5                	div    %ebp
  800d5b:	89 d0                	mov    %edx,%eax
  800d5d:	eb 99                	jmp    800cf8 <__umoddi3+0x38>
  800d5f:	90                   	nop
  800d60:	89 c8                	mov    %ecx,%eax
  800d62:	89 f2                	mov    %esi,%edx
  800d64:	83 c4 1c             	add    $0x1c,%esp
  800d67:	5b                   	pop    %ebx
  800d68:	5e                   	pop    %esi
  800d69:	5f                   	pop    %edi
  800d6a:	5d                   	pop    %ebp
  800d6b:	c3                   	ret    
  800d6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d70:	8b 34 24             	mov    (%esp),%esi
  800d73:	bf 20 00 00 00       	mov    $0x20,%edi
  800d78:	89 e9                	mov    %ebp,%ecx
  800d7a:	29 ef                	sub    %ebp,%edi
  800d7c:	d3 e0                	shl    %cl,%eax
  800d7e:	89 f9                	mov    %edi,%ecx
  800d80:	89 f2                	mov    %esi,%edx
  800d82:	d3 ea                	shr    %cl,%edx
  800d84:	89 e9                	mov    %ebp,%ecx
  800d86:	09 c2                	or     %eax,%edx
  800d88:	89 d8                	mov    %ebx,%eax
  800d8a:	89 14 24             	mov    %edx,(%esp)
  800d8d:	89 f2                	mov    %esi,%edx
  800d8f:	d3 e2                	shl    %cl,%edx
  800d91:	89 f9                	mov    %edi,%ecx
  800d93:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d97:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d9b:	d3 e8                	shr    %cl,%eax
  800d9d:	89 e9                	mov    %ebp,%ecx
  800d9f:	89 c6                	mov    %eax,%esi
  800da1:	d3 e3                	shl    %cl,%ebx
  800da3:	89 f9                	mov    %edi,%ecx
  800da5:	89 d0                	mov    %edx,%eax
  800da7:	d3 e8                	shr    %cl,%eax
  800da9:	89 e9                	mov    %ebp,%ecx
  800dab:	09 d8                	or     %ebx,%eax
  800dad:	89 d3                	mov    %edx,%ebx
  800daf:	89 f2                	mov    %esi,%edx
  800db1:	f7 34 24             	divl   (%esp)
  800db4:	89 d6                	mov    %edx,%esi
  800db6:	d3 e3                	shl    %cl,%ebx
  800db8:	f7 64 24 04          	mull   0x4(%esp)
  800dbc:	39 d6                	cmp    %edx,%esi
  800dbe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800dc2:	89 d1                	mov    %edx,%ecx
  800dc4:	89 c3                	mov    %eax,%ebx
  800dc6:	72 08                	jb     800dd0 <__umoddi3+0x110>
  800dc8:	75 11                	jne    800ddb <__umoddi3+0x11b>
  800dca:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800dce:	73 0b                	jae    800ddb <__umoddi3+0x11b>
  800dd0:	2b 44 24 04          	sub    0x4(%esp),%eax
  800dd4:	1b 14 24             	sbb    (%esp),%edx
  800dd7:	89 d1                	mov    %edx,%ecx
  800dd9:	89 c3                	mov    %eax,%ebx
  800ddb:	8b 54 24 08          	mov    0x8(%esp),%edx
  800ddf:	29 da                	sub    %ebx,%edx
  800de1:	19 ce                	sbb    %ecx,%esi
  800de3:	89 f9                	mov    %edi,%ecx
  800de5:	89 f0                	mov    %esi,%eax
  800de7:	d3 e0                	shl    %cl,%eax
  800de9:	89 e9                	mov    %ebp,%ecx
  800deb:	d3 ea                	shr    %cl,%edx
  800ded:	89 e9                	mov    %ebp,%ecx
  800def:	d3 ee                	shr    %cl,%esi
  800df1:	09 d0                	or     %edx,%eax
  800df3:	89 f2                	mov    %esi,%edx
  800df5:	83 c4 1c             	add    $0x1c,%esp
  800df8:	5b                   	pop    %ebx
  800df9:	5e                   	pop    %esi
  800dfa:	5f                   	pop    %edi
  800dfb:	5d                   	pop    %ebp
  800dfc:	c3                   	ret    
  800dfd:	8d 76 00             	lea    0x0(%esi),%esi
  800e00:	29 f9                	sub    %edi,%ecx
  800e02:	19 d6                	sbb    %edx,%esi
  800e04:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e08:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e0c:	e9 18 ff ff ff       	jmp    800d29 <__umoddi3+0x69>
