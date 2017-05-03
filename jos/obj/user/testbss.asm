
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
  80002c:	e8 cd 00 00 00       	call   8000fe <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

uint32_t bigarray[ARRAYSIZE];

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	int i;

	cprintf("Making sure bss works right...\n");
  800039:	c7 04 24 68 0f 80 00 	movl   $0x800f68,(%esp)
  800040:	e8 fb 01 00 00       	call   800240 <cprintf>
	for (i = 0; i < ARRAYSIZE; i++)
  800045:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004a:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800051:	00 
  800052:	74 20                	je     800074 <umain+0x41>
			panic("bigarray[%d] isn't cleared!\n", i);
  800054:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800058:	c7 44 24 08 e3 0f 80 	movl   $0x800fe3,0x8(%esp)
  80005f:	00 
  800060:	c7 44 24 04 11 00 00 	movl   $0x11,0x4(%esp)
  800067:	00 
  800068:	c7 04 24 00 10 80 00 	movl   $0x801000,(%esp)
  80006f:	e8 d3 00 00 00       	call   800147 <_panic>
umain(int argc, char **argv)
{
	int i;

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
  800074:	83 c0 01             	add    $0x1,%eax
  800077:	3d 00 00 10 00       	cmp    $0x100000,%eax
  80007c:	75 cc                	jne    80004a <umain+0x17>
  80007e:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
  800083:	89 04 85 20 20 80 00 	mov    %eax,0x802020(,%eax,4)

	cprintf("Making sure bss works right...\n");
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
  80008a:	83 c0 01             	add    $0x1,%eax
  80008d:	3d 00 00 10 00       	cmp    $0x100000,%eax
  800092:	75 ef                	jne    800083 <umain+0x50>
  800094:	b8 00 00 00 00       	mov    $0x0,%eax
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != i)
  800099:	39 04 85 20 20 80 00 	cmp    %eax,0x802020(,%eax,4)
  8000a0:	74 20                	je     8000c2 <umain+0x8f>
			panic("bigarray[%d] didn't hold its value!\n", i);
  8000a2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000a6:	c7 44 24 08 88 0f 80 	movl   $0x800f88,0x8(%esp)
  8000ad:	00 
  8000ae:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
  8000b5:	00 
  8000b6:	c7 04 24 00 10 80 00 	movl   $0x801000,(%esp)
  8000bd:	e8 85 00 00 00       	call   800147 <_panic>
	for (i = 0; i < ARRAYSIZE; i++)
		if (bigarray[i] != 0)
			panic("bigarray[%d] isn't cleared!\n", i);
	for (i = 0; i < ARRAYSIZE; i++)
		bigarray[i] = i;
	for (i = 0; i < ARRAYSIZE; i++)
  8000c2:	83 c0 01             	add    $0x1,%eax
  8000c5:	3d 00 00 10 00       	cmp    $0x100000,%eax
  8000ca:	75 cd                	jne    800099 <umain+0x66>
		if (bigarray[i] != i)
			panic("bigarray[%d] didn't hold its value!\n", i);

	cprintf("Yes, good.  Now doing a wild write off the end...\n");
  8000cc:	c7 04 24 b0 0f 80 00 	movl   $0x800fb0,(%esp)
  8000d3:	e8 68 01 00 00       	call   800240 <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000d8:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000df:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000e2:	c7 44 24 08 0f 10 80 	movl   $0x80100f,0x8(%esp)
  8000e9:	00 
  8000ea:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  8000f1:	00 
  8000f2:	c7 04 24 00 10 80 00 	movl   $0x801000,(%esp)
  8000f9:	e8 49 00 00 00       	call   800147 <_panic>

008000fe <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000fe:	55                   	push   %ebp
  8000ff:	89 e5                	mov    %esp,%ebp
  800101:	83 ec 18             	sub    $0x18,%esp
  800104:	8b 45 08             	mov    0x8(%ebp),%eax
  800107:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80010a:	c7 05 20 20 c0 00 00 	movl   $0x0,0xc02020
  800111:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800114:	85 c0                	test   %eax,%eax
  800116:	7e 08                	jle    800120 <libmain+0x22>
		binaryname = argv[0];
  800118:	8b 0a                	mov    (%edx),%ecx
  80011a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800120:	89 54 24 04          	mov    %edx,0x4(%esp)
  800124:	89 04 24             	mov    %eax,(%esp)
  800127:	e8 07 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80012c:	e8 02 00 00 00       	call   800133 <exit>
}
  800131:	c9                   	leave  
  800132:	c3                   	ret    

00800133 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800133:	55                   	push   %ebp
  800134:	89 e5                	mov    %esp,%ebp
  800136:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800139:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800140:	e8 1d 0b 00 00       	call   800c62 <sys_env_destroy>
}
  800145:	c9                   	leave  
  800146:	c3                   	ret    

00800147 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800147:	55                   	push   %ebp
  800148:	89 e5                	mov    %esp,%ebp
  80014a:	56                   	push   %esi
  80014b:	53                   	push   %ebx
  80014c:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80014f:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800152:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800158:	e8 3e 0b 00 00       	call   800c9b <sys_getenvid>
  80015d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800160:	89 54 24 10          	mov    %edx,0x10(%esp)
  800164:	8b 55 08             	mov    0x8(%ebp),%edx
  800167:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80016b:	89 74 24 08          	mov    %esi,0x8(%esp)
  80016f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800173:	c7 04 24 30 10 80 00 	movl   $0x801030,(%esp)
  80017a:	e8 c1 00 00 00       	call   800240 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80017f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800183:	8b 45 10             	mov    0x10(%ebp),%eax
  800186:	89 04 24             	mov    %eax,(%esp)
  800189:	e8 51 00 00 00       	call   8001df <vcprintf>
	cprintf("\n");
  80018e:	c7 04 24 fe 0f 80 00 	movl   $0x800ffe,(%esp)
  800195:	e8 a6 00 00 00       	call   800240 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80019a:	cc                   	int3   
  80019b:	eb fd                	jmp    80019a <_panic+0x53>

0080019d <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80019d:	55                   	push   %ebp
  80019e:	89 e5                	mov    %esp,%ebp
  8001a0:	53                   	push   %ebx
  8001a1:	83 ec 14             	sub    $0x14,%esp
  8001a4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001a7:	8b 13                	mov    (%ebx),%edx
  8001a9:	8d 42 01             	lea    0x1(%edx),%eax
  8001ac:	89 03                	mov    %eax,(%ebx)
  8001ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001b1:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001b5:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001ba:	75 19                	jne    8001d5 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001bc:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001c3:	00 
  8001c4:	8d 43 08             	lea    0x8(%ebx),%eax
  8001c7:	89 04 24             	mov    %eax,(%esp)
  8001ca:	e8 20 0a 00 00       	call   800bef <sys_cputs>
		b->idx = 0;
  8001cf:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001d5:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001d9:	83 c4 14             	add    $0x14,%esp
  8001dc:	5b                   	pop    %ebx
  8001dd:	5d                   	pop    %ebp
  8001de:	c3                   	ret    

008001df <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001df:	55                   	push   %ebp
  8001e0:	89 e5                	mov    %esp,%ebp
  8001e2:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8001e8:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001ef:	00 00 00 
	b.cnt = 0;
  8001f2:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001f9:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001fc:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800203:	8b 45 08             	mov    0x8(%ebp),%eax
  800206:	89 44 24 08          	mov    %eax,0x8(%esp)
  80020a:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800210:	89 44 24 04          	mov    %eax,0x4(%esp)
  800214:	c7 04 24 9d 01 80 00 	movl   $0x80019d,(%esp)
  80021b:	e8 e0 01 00 00       	call   800400 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800220:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800226:	89 44 24 04          	mov    %eax,0x4(%esp)
  80022a:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800230:	89 04 24             	mov    %eax,(%esp)
  800233:	e8 b7 09 00 00       	call   800bef <sys_cputs>

	return b.cnt;
}
  800238:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80023e:	c9                   	leave  
  80023f:	c3                   	ret    

00800240 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800240:	55                   	push   %ebp
  800241:	89 e5                	mov    %esp,%ebp
  800243:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800246:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800249:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024d:	8b 45 08             	mov    0x8(%ebp),%eax
  800250:	89 04 24             	mov    %eax,(%esp)
  800253:	e8 87 ff ff ff       	call   8001df <vcprintf>
	va_end(ap);

	return cnt;
}
  800258:	c9                   	leave  
  800259:	c3                   	ret    
  80025a:	66 90                	xchg   %ax,%ax
  80025c:	66 90                	xchg   %ax,%ax
  80025e:	66 90                	xchg   %ax,%ax

00800260 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800260:	55                   	push   %ebp
  800261:	89 e5                	mov    %esp,%ebp
  800263:	57                   	push   %edi
  800264:	56                   	push   %esi
  800265:	53                   	push   %ebx
  800266:	83 ec 3c             	sub    $0x3c,%esp
  800269:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80026c:	89 d7                	mov    %edx,%edi
  80026e:	8b 45 08             	mov    0x8(%ebp),%eax
  800271:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800274:	8b 45 0c             	mov    0xc(%ebp),%eax
  800277:	89 c3                	mov    %eax,%ebx
  800279:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80027c:	8b 45 10             	mov    0x10(%ebp),%eax
  80027f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800282:	b9 00 00 00 00       	mov    $0x0,%ecx
  800287:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80028a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80028d:	39 d9                	cmp    %ebx,%ecx
  80028f:	72 05                	jb     800296 <printnum+0x36>
  800291:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800294:	77 69                	ja     8002ff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800296:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800299:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80029d:	83 ee 01             	sub    $0x1,%esi
  8002a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002a4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002a8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002ac:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002b0:	89 c3                	mov    %eax,%ebx
  8002b2:	89 d6                	mov    %edx,%esi
  8002b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002ba:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002c5:	89 04 24             	mov    %eax,(%esp)
  8002c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002cf:	e8 0c 0a 00 00       	call   800ce0 <__udivdi3>
  8002d4:	89 d9                	mov    %ebx,%ecx
  8002d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002da:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002de:	89 04 24             	mov    %eax,(%esp)
  8002e1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002e5:	89 fa                	mov    %edi,%edx
  8002e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002ea:	e8 71 ff ff ff       	call   800260 <printnum>
  8002ef:	eb 1b                	jmp    80030c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002f5:	8b 45 18             	mov    0x18(%ebp),%eax
  8002f8:	89 04 24             	mov    %eax,(%esp)
  8002fb:	ff d3                	call   *%ebx
  8002fd:	eb 03                	jmp    800302 <printnum+0xa2>
  8002ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800302:	83 ee 01             	sub    $0x1,%esi
  800305:	85 f6                	test   %esi,%esi
  800307:	7f e8                	jg     8002f1 <printnum+0x91>
  800309:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80030c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800310:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800314:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800317:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80031a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80031e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800322:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800325:	89 04 24             	mov    %eax,(%esp)
  800328:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80032b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80032f:	e8 dc 0a 00 00       	call   800e10 <__umoddi3>
  800334:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800338:	0f be 80 54 10 80 00 	movsbl 0x801054(%eax),%eax
  80033f:	89 04 24             	mov    %eax,(%esp)
  800342:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800345:	ff d0                	call   *%eax
}
  800347:	83 c4 3c             	add    $0x3c,%esp
  80034a:	5b                   	pop    %ebx
  80034b:	5e                   	pop    %esi
  80034c:	5f                   	pop    %edi
  80034d:	5d                   	pop    %ebp
  80034e:	c3                   	ret    

0080034f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80034f:	55                   	push   %ebp
  800350:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800352:	83 fa 01             	cmp    $0x1,%edx
  800355:	7e 0e                	jle    800365 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800357:	8b 10                	mov    (%eax),%edx
  800359:	8d 4a 08             	lea    0x8(%edx),%ecx
  80035c:	89 08                	mov    %ecx,(%eax)
  80035e:	8b 02                	mov    (%edx),%eax
  800360:	8b 52 04             	mov    0x4(%edx),%edx
  800363:	eb 22                	jmp    800387 <getuint+0x38>
	else if (lflag)
  800365:	85 d2                	test   %edx,%edx
  800367:	74 10                	je     800379 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800369:	8b 10                	mov    (%eax),%edx
  80036b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80036e:	89 08                	mov    %ecx,(%eax)
  800370:	8b 02                	mov    (%edx),%eax
  800372:	ba 00 00 00 00       	mov    $0x0,%edx
  800377:	eb 0e                	jmp    800387 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800379:	8b 10                	mov    (%eax),%edx
  80037b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80037e:	89 08                	mov    %ecx,(%eax)
  800380:	8b 02                	mov    (%edx),%eax
  800382:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800387:	5d                   	pop    %ebp
  800388:	c3                   	ret    

00800389 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800389:	55                   	push   %ebp
  80038a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  80038c:	83 fa 01             	cmp    $0x1,%edx
  80038f:	7e 0e                	jle    80039f <getint+0x16>
		return va_arg(*ap, long long);
  800391:	8b 10                	mov    (%eax),%edx
  800393:	8d 4a 08             	lea    0x8(%edx),%ecx
  800396:	89 08                	mov    %ecx,(%eax)
  800398:	8b 02                	mov    (%edx),%eax
  80039a:	8b 52 04             	mov    0x4(%edx),%edx
  80039d:	eb 1a                	jmp    8003b9 <getint+0x30>
	else if (lflag)
  80039f:	85 d2                	test   %edx,%edx
  8003a1:	74 0c                	je     8003af <getint+0x26>
		return va_arg(*ap, long);
  8003a3:	8b 10                	mov    (%eax),%edx
  8003a5:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003a8:	89 08                	mov    %ecx,(%eax)
  8003aa:	8b 02                	mov    (%edx),%eax
  8003ac:	99                   	cltd   
  8003ad:	eb 0a                	jmp    8003b9 <getint+0x30>
	else
		return va_arg(*ap, int);
  8003af:	8b 10                	mov    (%eax),%edx
  8003b1:	8d 4a 04             	lea    0x4(%edx),%ecx
  8003b4:	89 08                	mov    %ecx,(%eax)
  8003b6:	8b 02                	mov    (%edx),%eax
  8003b8:	99                   	cltd   
}
  8003b9:	5d                   	pop    %ebp
  8003ba:	c3                   	ret    

008003bb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8003bb:	55                   	push   %ebp
  8003bc:	89 e5                	mov    %esp,%ebp
  8003be:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8003c1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003c5:	8b 10                	mov    (%eax),%edx
  8003c7:	3b 50 04             	cmp    0x4(%eax),%edx
  8003ca:	73 0a                	jae    8003d6 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003cc:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003cf:	89 08                	mov    %ecx,(%eax)
  8003d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8003d4:	88 02                	mov    %al,(%edx)
}
  8003d6:	5d                   	pop    %ebp
  8003d7:	c3                   	ret    

008003d8 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003d8:	55                   	push   %ebp
  8003d9:	89 e5                	mov    %esp,%ebp
  8003db:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003de:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003e1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003e5:	8b 45 10             	mov    0x10(%ebp),%eax
  8003e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003f3:	8b 45 08             	mov    0x8(%ebp),%eax
  8003f6:	89 04 24             	mov    %eax,(%esp)
  8003f9:	e8 02 00 00 00       	call   800400 <vprintfmt>
	va_end(ap);
}
  8003fe:	c9                   	leave  
  8003ff:	c3                   	ret    

00800400 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  800400:	55                   	push   %ebp
  800401:	89 e5                	mov    %esp,%ebp
  800403:	57                   	push   %edi
  800404:	56                   	push   %esi
  800405:	53                   	push   %ebx
  800406:	83 ec 3c             	sub    $0x3c,%esp
  800409:	8b 75 0c             	mov    0xc(%ebp),%esi
  80040c:	8b 7d 10             	mov    0x10(%ebp),%edi
  80040f:	eb 14                	jmp    800425 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  800411:	85 c0                	test   %eax,%eax
  800413:	0f 84 63 03 00 00    	je     80077c <vprintfmt+0x37c>
				return;
			putch(ch, putdat);
  800419:	89 74 24 04          	mov    %esi,0x4(%esp)
  80041d:	89 04 24             	mov    %eax,(%esp)
  800420:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800423:	89 df                	mov    %ebx,%edi
  800425:	8d 5f 01             	lea    0x1(%edi),%ebx
  800428:	0f b6 07             	movzbl (%edi),%eax
  80042b:	83 f8 25             	cmp    $0x25,%eax
  80042e:	75 e1                	jne    800411 <vprintfmt+0x11>
  800430:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800434:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  80043b:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800442:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800449:	ba 00 00 00 00       	mov    $0x0,%edx
  80044e:	eb 1d                	jmp    80046d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800450:	89 fb                	mov    %edi,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
  800452:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800456:	eb 15                	jmp    80046d <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800458:	89 fb                	mov    %edi,%ebx
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80045a:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80045e:	eb 0d                	jmp    80046d <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  800460:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800463:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800466:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046d:	8d 7b 01             	lea    0x1(%ebx),%edi
  800470:	0f b6 0b             	movzbl (%ebx),%ecx
  800473:	0f b6 c1             	movzbl %cl,%eax
  800476:	83 e9 23             	sub    $0x23,%ecx
  800479:	80 f9 55             	cmp    $0x55,%cl
  80047c:	0f 87 da 02 00 00    	ja     80075c <vprintfmt+0x35c>
  800482:	0f b6 c9             	movzbl %cl,%ecx
  800485:	ff 24 8d e4 10 80 00 	jmp    *0x8010e4(,%ecx,4)
  80048c:	89 fb                	mov    %edi,%ebx
  80048e:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800493:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800496:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  80049a:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
  80049d:	8d 78 d0             	lea    -0x30(%eax),%edi
  8004a0:	83 ff 09             	cmp    $0x9,%edi
  8004a3:	77 36                	ja     8004db <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8004a5:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8004a8:	eb e9                	jmp    800493 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8004aa:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ad:	8d 48 04             	lea    0x4(%eax),%ecx
  8004b0:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8004b3:	8b 00                	mov    (%eax),%eax
  8004b5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004b8:	89 fb                	mov    %edi,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8004ba:	eb 22                	jmp    8004de <vprintfmt+0xde>
  8004bc:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8004bf:	85 c9                	test   %ecx,%ecx
  8004c1:	b8 00 00 00 00       	mov    $0x0,%eax
  8004c6:	0f 49 c1             	cmovns %ecx,%eax
  8004c9:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cc:	89 fb                	mov    %edi,%ebx
  8004ce:	eb 9d                	jmp    80046d <vprintfmt+0x6d>
  8004d0:	89 fb                	mov    %edi,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8004d2:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8004d9:	eb 92                	jmp    80046d <vprintfmt+0x6d>
  8004db:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8004de:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004e2:	79 89                	jns    80046d <vprintfmt+0x6d>
  8004e4:	e9 77 ff ff ff       	jmp    800460 <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8004e9:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004ec:	89 fb                	mov    %edi,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8004ee:	e9 7a ff ff ff       	jmp    80046d <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8004f3:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f6:	8d 50 04             	lea    0x4(%eax),%edx
  8004f9:	89 55 14             	mov    %edx,0x14(%ebp)
  8004fc:	89 74 24 04          	mov    %esi,0x4(%esp)
  800500:	8b 00                	mov    (%eax),%eax
  800502:	89 04 24             	mov    %eax,(%esp)
  800505:	ff 55 08             	call   *0x8(%ebp)
			break;
  800508:	e9 18 ff ff ff       	jmp    800425 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80050d:	8b 45 14             	mov    0x14(%ebp),%eax
  800510:	8d 50 04             	lea    0x4(%eax),%edx
  800513:	89 55 14             	mov    %edx,0x14(%ebp)
  800516:	8b 00                	mov    (%eax),%eax
  800518:	99                   	cltd   
  800519:	31 d0                	xor    %edx,%eax
  80051b:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80051d:	83 f8 06             	cmp    $0x6,%eax
  800520:	7f 0b                	jg     80052d <vprintfmt+0x12d>
  800522:	8b 14 85 3c 12 80 00 	mov    0x80123c(,%eax,4),%edx
  800529:	85 d2                	test   %edx,%edx
  80052b:	75 20                	jne    80054d <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80052d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800531:	c7 44 24 08 6c 10 80 	movl   $0x80106c,0x8(%esp)
  800538:	00 
  800539:	89 74 24 04          	mov    %esi,0x4(%esp)
  80053d:	8b 45 08             	mov    0x8(%ebp),%eax
  800540:	89 04 24             	mov    %eax,(%esp)
  800543:	e8 90 fe ff ff       	call   8003d8 <printfmt>
  800548:	e9 d8 fe ff ff       	jmp    800425 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80054d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800551:	c7 44 24 08 75 10 80 	movl   $0x801075,0x8(%esp)
  800558:	00 
  800559:	89 74 24 04          	mov    %esi,0x4(%esp)
  80055d:	8b 45 08             	mov    0x8(%ebp),%eax
  800560:	89 04 24             	mov    %eax,(%esp)
  800563:	e8 70 fe ff ff       	call   8003d8 <printfmt>
  800568:	e9 b8 fe ff ff       	jmp    800425 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80056d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800570:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800573:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800576:	8b 45 14             	mov    0x14(%ebp),%eax
  800579:	8d 50 04             	lea    0x4(%eax),%edx
  80057c:	89 55 14             	mov    %edx,0x14(%ebp)
  80057f:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
  800581:	85 db                	test   %ebx,%ebx
  800583:	b8 65 10 80 00       	mov    $0x801065,%eax
  800588:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
  80058b:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80058f:	0f 84 97 00 00 00    	je     80062c <vprintfmt+0x22c>
  800595:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800599:	0f 8e 9b 00 00 00    	jle    80063a <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80059f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005a3:	89 1c 24             	mov    %ebx,(%esp)
  8005a6:	e8 7d 02 00 00       	call   800828 <strnlen>
  8005ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8005ae:	29 c2                	sub    %eax,%edx
  8005b0:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8005b3:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8005b7:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8005ba:	89 5d d8             	mov    %ebx,-0x28(%ebp)
  8005bd:	89 d3                	mov    %edx,%ebx
  8005bf:	89 7d 10             	mov    %edi,0x10(%ebp)
  8005c2:	8b 7d 08             	mov    0x8(%ebp),%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005c5:	eb 0f                	jmp    8005d6 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8005c7:	89 74 24 04          	mov    %esi,0x4(%esp)
  8005cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005ce:	89 04 24             	mov    %eax,(%esp)
  8005d1:	ff d7                	call   *%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005d3:	83 eb 01             	sub    $0x1,%ebx
  8005d6:	85 db                	test   %ebx,%ebx
  8005d8:	7f ed                	jg     8005c7 <vprintfmt+0x1c7>
  8005da:	8b 5d d8             	mov    -0x28(%ebp),%ebx
  8005dd:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8005e0:	85 d2                	test   %edx,%edx
  8005e2:	b8 00 00 00 00       	mov    $0x0,%eax
  8005e7:	0f 49 c2             	cmovns %edx,%eax
  8005ea:	29 c2                	sub    %eax,%edx
  8005ec:	89 75 0c             	mov    %esi,0xc(%ebp)
  8005ef:	89 d6                	mov    %edx,%esi
  8005f1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  8005f4:	eb 50                	jmp    800646 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005f6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005fa:	74 1e                	je     80061a <vprintfmt+0x21a>
  8005fc:	0f be d2             	movsbl %dl,%edx
  8005ff:	83 ea 20             	sub    $0x20,%edx
  800602:	83 fa 5e             	cmp    $0x5e,%edx
  800605:	76 13                	jbe    80061a <vprintfmt+0x21a>
					putch('?', putdat);
  800607:	8b 45 0c             	mov    0xc(%ebp),%eax
  80060a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80060e:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800615:	ff 55 08             	call   *0x8(%ebp)
  800618:	eb 0d                	jmp    800627 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  80061a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80061d:	89 54 24 04          	mov    %edx,0x4(%esp)
  800621:	89 04 24             	mov    %eax,(%esp)
  800624:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800627:	83 ee 01             	sub    $0x1,%esi
  80062a:	eb 1a                	jmp    800646 <vprintfmt+0x246>
  80062c:	89 75 0c             	mov    %esi,0xc(%ebp)
  80062f:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800632:	89 7d 10             	mov    %edi,0x10(%ebp)
  800635:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800638:	eb 0c                	jmp    800646 <vprintfmt+0x246>
  80063a:	89 75 0c             	mov    %esi,0xc(%ebp)
  80063d:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800640:	89 7d 10             	mov    %edi,0x10(%ebp)
  800643:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800646:	83 c3 01             	add    $0x1,%ebx
  800649:	0f b6 53 ff          	movzbl -0x1(%ebx),%edx
  80064d:	0f be c2             	movsbl %dl,%eax
  800650:	85 c0                	test   %eax,%eax
  800652:	74 25                	je     800679 <vprintfmt+0x279>
  800654:	85 ff                	test   %edi,%edi
  800656:	78 9e                	js     8005f6 <vprintfmt+0x1f6>
  800658:	83 ef 01             	sub    $0x1,%edi
  80065b:	79 99                	jns    8005f6 <vprintfmt+0x1f6>
  80065d:	89 f3                	mov    %esi,%ebx
  80065f:	8b 75 0c             	mov    0xc(%ebp),%esi
  800662:	8b 7d 08             	mov    0x8(%ebp),%edi
  800665:	eb 1a                	jmp    800681 <vprintfmt+0x281>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800667:	89 74 24 04          	mov    %esi,0x4(%esp)
  80066b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800672:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800674:	83 eb 01             	sub    $0x1,%ebx
  800677:	eb 08                	jmp    800681 <vprintfmt+0x281>
  800679:	89 f3                	mov    %esi,%ebx
  80067b:	8b 7d 08             	mov    0x8(%ebp),%edi
  80067e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800681:	85 db                	test   %ebx,%ebx
  800683:	7f e2                	jg     800667 <vprintfmt+0x267>
  800685:	89 7d 08             	mov    %edi,0x8(%ebp)
  800688:	8b 7d 10             	mov    0x10(%ebp),%edi
  80068b:	e9 95 fd ff ff       	jmp    800425 <vprintfmt+0x25>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800690:	8d 45 14             	lea    0x14(%ebp),%eax
  800693:	e8 f1 fc ff ff       	call   800389 <getint>
  800698:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80069b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80069e:	bb 0a 00 00 00       	mov    $0xa,%ebx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006a3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8006a7:	79 7b                	jns    800724 <vprintfmt+0x324>
				putch('-', putdat);
  8006a9:	89 74 24 04          	mov    %esi,0x4(%esp)
  8006ad:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006b4:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006ba:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8006bd:	f7 d8                	neg    %eax
  8006bf:	83 d2 00             	adc    $0x0,%edx
  8006c2:	f7 da                	neg    %edx
  8006c4:	eb 5e                	jmp    800724 <vprintfmt+0x324>
			base = 10;
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006c6:	8d 45 14             	lea    0x14(%ebp),%eax
  8006c9:	e8 81 fc ff ff       	call   80034f <getuint>
			base = 10;
  8006ce:	bb 0a 00 00 00       	mov    $0xa,%ebx
			goto number;
  8006d3:	eb 4f                	jmp    800724 <vprintfmt+0x324>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8006d5:	8d 45 14             	lea    0x14(%ebp),%eax
  8006d8:	e8 72 fc ff ff       	call   80034f <getuint>
			base = 8;
  8006dd:	bb 08 00 00 00       	mov    $0x8,%ebx
			goto number;
  8006e2:	eb 40                	jmp    800724 <vprintfmt+0x324>

		// pointer
		case 'p':
			putch('0', putdat);
  8006e4:	89 74 24 04          	mov    %esi,0x4(%esp)
  8006e8:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006ef:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8006f2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8006f6:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006fd:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800700:	8b 45 14             	mov    0x14(%ebp),%eax
  800703:	8d 50 04             	lea    0x4(%eax),%edx
  800706:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800709:	8b 00                	mov    (%eax),%eax
  80070b:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800710:	bb 10 00 00 00       	mov    $0x10,%ebx
			goto number;
  800715:	eb 0d                	jmp    800724 <vprintfmt+0x324>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800717:	8d 45 14             	lea    0x14(%ebp),%eax
  80071a:	e8 30 fc ff ff       	call   80034f <getuint>
			base = 16;
  80071f:	bb 10 00 00 00       	mov    $0x10,%ebx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800724:	0f be 4d d8          	movsbl -0x28(%ebp),%ecx
  800728:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80072c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80072f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800733:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800737:	89 04 24             	mov    %eax,(%esp)
  80073a:	89 54 24 04          	mov    %edx,0x4(%esp)
  80073e:	89 f2                	mov    %esi,%edx
  800740:	8b 45 08             	mov    0x8(%ebp),%eax
  800743:	e8 18 fb ff ff       	call   800260 <printnum>
			break;
  800748:	e9 d8 fc ff ff       	jmp    800425 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80074d:	89 74 24 04          	mov    %esi,0x4(%esp)
  800751:	89 04 24             	mov    %eax,(%esp)
  800754:	ff 55 08             	call   *0x8(%ebp)
			break;
  800757:	e9 c9 fc ff ff       	jmp    800425 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80075c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800760:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800767:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  80076a:	89 df                	mov    %ebx,%edi
  80076c:	eb 03                	jmp    800771 <vprintfmt+0x371>
  80076e:	83 ef 01             	sub    $0x1,%edi
  800771:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  800775:	75 f7                	jne    80076e <vprintfmt+0x36e>
  800777:	e9 a9 fc ff ff       	jmp    800425 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80077c:	83 c4 3c             	add    $0x3c,%esp
  80077f:	5b                   	pop    %ebx
  800780:	5e                   	pop    %esi
  800781:	5f                   	pop    %edi
  800782:	5d                   	pop    %ebp
  800783:	c3                   	ret    

00800784 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800784:	55                   	push   %ebp
  800785:	89 e5                	mov    %esp,%ebp
  800787:	83 ec 28             	sub    $0x28,%esp
  80078a:	8b 45 08             	mov    0x8(%ebp),%eax
  80078d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800790:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800793:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800797:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  80079a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007a1:	85 c0                	test   %eax,%eax
  8007a3:	74 30                	je     8007d5 <vsnprintf+0x51>
  8007a5:	85 d2                	test   %edx,%edx
  8007a7:	7e 2c                	jle    8007d5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007a9:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007b0:	8b 45 10             	mov    0x10(%ebp),%eax
  8007b3:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007b7:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007be:	c7 04 24 bb 03 80 00 	movl   $0x8003bb,(%esp)
  8007c5:	e8 36 fc ff ff       	call   800400 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007ca:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007cd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8007d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007d3:	eb 05                	jmp    8007da <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007d5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007da:	c9                   	leave  
  8007db:	c3                   	ret    

008007dc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007dc:	55                   	push   %ebp
  8007dd:	89 e5                	mov    %esp,%ebp
  8007df:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007e2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007e5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007e9:	8b 45 10             	mov    0x10(%ebp),%eax
  8007ec:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007f7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007fa:	89 04 24             	mov    %eax,(%esp)
  8007fd:	e8 82 ff ff ff       	call   800784 <vsnprintf>
	va_end(ap);

	return rc;
}
  800802:	c9                   	leave  
  800803:	c3                   	ret    
  800804:	66 90                	xchg   %ax,%ax
  800806:	66 90                	xchg   %ax,%ax
  800808:	66 90                	xchg   %ax,%ax
  80080a:	66 90                	xchg   %ax,%ax
  80080c:	66 90                	xchg   %ax,%ax
  80080e:	66 90                	xchg   %ax,%ax

00800810 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800810:	55                   	push   %ebp
  800811:	89 e5                	mov    %esp,%ebp
  800813:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800816:	b8 00 00 00 00       	mov    $0x0,%eax
  80081b:	eb 03                	jmp    800820 <strlen+0x10>
		n++;
  80081d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800820:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800824:	75 f7                	jne    80081d <strlen+0xd>
		n++;
	return n;
}
  800826:	5d                   	pop    %ebp
  800827:	c3                   	ret    

00800828 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800828:	55                   	push   %ebp
  800829:	89 e5                	mov    %esp,%ebp
  80082b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80082e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800831:	b8 00 00 00 00       	mov    $0x0,%eax
  800836:	eb 03                	jmp    80083b <strnlen+0x13>
		n++;
  800838:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80083b:	39 d0                	cmp    %edx,%eax
  80083d:	74 06                	je     800845 <strnlen+0x1d>
  80083f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800843:	75 f3                	jne    800838 <strnlen+0x10>
		n++;
	return n;
}
  800845:	5d                   	pop    %ebp
  800846:	c3                   	ret    

00800847 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800847:	55                   	push   %ebp
  800848:	89 e5                	mov    %esp,%ebp
  80084a:	53                   	push   %ebx
  80084b:	8b 45 08             	mov    0x8(%ebp),%eax
  80084e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800851:	89 c2                	mov    %eax,%edx
  800853:	83 c2 01             	add    $0x1,%edx
  800856:	83 c1 01             	add    $0x1,%ecx
  800859:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80085d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800860:	84 db                	test   %bl,%bl
  800862:	75 ef                	jne    800853 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800864:	5b                   	pop    %ebx
  800865:	5d                   	pop    %ebp
  800866:	c3                   	ret    

00800867 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800867:	55                   	push   %ebp
  800868:	89 e5                	mov    %esp,%ebp
  80086a:	53                   	push   %ebx
  80086b:	83 ec 08             	sub    $0x8,%esp
  80086e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800871:	89 1c 24             	mov    %ebx,(%esp)
  800874:	e8 97 ff ff ff       	call   800810 <strlen>
	strcpy(dst + len, src);
  800879:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800880:	01 d8                	add    %ebx,%eax
  800882:	89 04 24             	mov    %eax,(%esp)
  800885:	e8 bd ff ff ff       	call   800847 <strcpy>
	return dst;
}
  80088a:	89 d8                	mov    %ebx,%eax
  80088c:	83 c4 08             	add    $0x8,%esp
  80088f:	5b                   	pop    %ebx
  800890:	5d                   	pop    %ebp
  800891:	c3                   	ret    

00800892 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800892:	55                   	push   %ebp
  800893:	89 e5                	mov    %esp,%ebp
  800895:	56                   	push   %esi
  800896:	53                   	push   %ebx
  800897:	8b 75 08             	mov    0x8(%ebp),%esi
  80089a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80089d:	89 f3                	mov    %esi,%ebx
  80089f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008a2:	89 f2                	mov    %esi,%edx
  8008a4:	eb 0f                	jmp    8008b5 <strncpy+0x23>
		*dst++ = *src;
  8008a6:	83 c2 01             	add    $0x1,%edx
  8008a9:	0f b6 01             	movzbl (%ecx),%eax
  8008ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008af:	80 39 01             	cmpb   $0x1,(%ecx)
  8008b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008b5:	39 da                	cmp    %ebx,%edx
  8008b7:	75 ed                	jne    8008a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008b9:	89 f0                	mov    %esi,%eax
  8008bb:	5b                   	pop    %ebx
  8008bc:	5e                   	pop    %esi
  8008bd:	5d                   	pop    %ebp
  8008be:	c3                   	ret    

008008bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008bf:	55                   	push   %ebp
  8008c0:	89 e5                	mov    %esp,%ebp
  8008c2:	56                   	push   %esi
  8008c3:	53                   	push   %ebx
  8008c4:	8b 75 08             	mov    0x8(%ebp),%esi
  8008c7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8008cd:	89 f0                	mov    %esi,%eax
  8008cf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008d3:	85 c9                	test   %ecx,%ecx
  8008d5:	75 0b                	jne    8008e2 <strlcpy+0x23>
  8008d7:	eb 1d                	jmp    8008f6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008d9:	83 c0 01             	add    $0x1,%eax
  8008dc:	83 c2 01             	add    $0x1,%edx
  8008df:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008e2:	39 d8                	cmp    %ebx,%eax
  8008e4:	74 0b                	je     8008f1 <strlcpy+0x32>
  8008e6:	0f b6 0a             	movzbl (%edx),%ecx
  8008e9:	84 c9                	test   %cl,%cl
  8008eb:	75 ec                	jne    8008d9 <strlcpy+0x1a>
  8008ed:	89 c2                	mov    %eax,%edx
  8008ef:	eb 02                	jmp    8008f3 <strlcpy+0x34>
  8008f1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8008f3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8008f6:	29 f0                	sub    %esi,%eax
}
  8008f8:	5b                   	pop    %ebx
  8008f9:	5e                   	pop    %esi
  8008fa:	5d                   	pop    %ebp
  8008fb:	c3                   	ret    

008008fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008fc:	55                   	push   %ebp
  8008fd:	89 e5                	mov    %esp,%ebp
  8008ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800902:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800905:	eb 06                	jmp    80090d <strcmp+0x11>
		p++, q++;
  800907:	83 c1 01             	add    $0x1,%ecx
  80090a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80090d:	0f b6 01             	movzbl (%ecx),%eax
  800910:	84 c0                	test   %al,%al
  800912:	74 04                	je     800918 <strcmp+0x1c>
  800914:	3a 02                	cmp    (%edx),%al
  800916:	74 ef                	je     800907 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800918:	0f b6 c0             	movzbl %al,%eax
  80091b:	0f b6 12             	movzbl (%edx),%edx
  80091e:	29 d0                	sub    %edx,%eax
}
  800920:	5d                   	pop    %ebp
  800921:	c3                   	ret    

00800922 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800922:	55                   	push   %ebp
  800923:	89 e5                	mov    %esp,%ebp
  800925:	53                   	push   %ebx
  800926:	8b 45 08             	mov    0x8(%ebp),%eax
  800929:	8b 55 0c             	mov    0xc(%ebp),%edx
  80092c:	89 c3                	mov    %eax,%ebx
  80092e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800931:	eb 06                	jmp    800939 <strncmp+0x17>
		n--, p++, q++;
  800933:	83 c0 01             	add    $0x1,%eax
  800936:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800939:	39 d8                	cmp    %ebx,%eax
  80093b:	74 15                	je     800952 <strncmp+0x30>
  80093d:	0f b6 08             	movzbl (%eax),%ecx
  800940:	84 c9                	test   %cl,%cl
  800942:	74 04                	je     800948 <strncmp+0x26>
  800944:	3a 0a                	cmp    (%edx),%cl
  800946:	74 eb                	je     800933 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800948:	0f b6 00             	movzbl (%eax),%eax
  80094b:	0f b6 12             	movzbl (%edx),%edx
  80094e:	29 d0                	sub    %edx,%eax
  800950:	eb 05                	jmp    800957 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800952:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800957:	5b                   	pop    %ebx
  800958:	5d                   	pop    %ebp
  800959:	c3                   	ret    

0080095a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80095a:	55                   	push   %ebp
  80095b:	89 e5                	mov    %esp,%ebp
  80095d:	8b 45 08             	mov    0x8(%ebp),%eax
  800960:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800964:	eb 07                	jmp    80096d <strchr+0x13>
		if (*s == c)
  800966:	38 ca                	cmp    %cl,%dl
  800968:	74 0f                	je     800979 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80096a:	83 c0 01             	add    $0x1,%eax
  80096d:	0f b6 10             	movzbl (%eax),%edx
  800970:	84 d2                	test   %dl,%dl
  800972:	75 f2                	jne    800966 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800974:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800979:	5d                   	pop    %ebp
  80097a:	c3                   	ret    

0080097b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80097b:	55                   	push   %ebp
  80097c:	89 e5                	mov    %esp,%ebp
  80097e:	8b 45 08             	mov    0x8(%ebp),%eax
  800981:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800985:	eb 07                	jmp    80098e <strfind+0x13>
		if (*s == c)
  800987:	38 ca                	cmp    %cl,%dl
  800989:	74 0a                	je     800995 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80098b:	83 c0 01             	add    $0x1,%eax
  80098e:	0f b6 10             	movzbl (%eax),%edx
  800991:	84 d2                	test   %dl,%dl
  800993:	75 f2                	jne    800987 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800995:	5d                   	pop    %ebp
  800996:	c3                   	ret    

00800997 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800997:	55                   	push   %ebp
  800998:	89 e5                	mov    %esp,%ebp
  80099a:	57                   	push   %edi
  80099b:	56                   	push   %esi
  80099c:	53                   	push   %ebx
  80099d:	8b 55 08             	mov    0x8(%ebp),%edx
  8009a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8009a3:	85 c9                	test   %ecx,%ecx
  8009a5:	74 37                	je     8009de <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009a7:	f6 c2 03             	test   $0x3,%dl
  8009aa:	75 2a                	jne    8009d6 <memset+0x3f>
  8009ac:	f6 c1 03             	test   $0x3,%cl
  8009af:	75 25                	jne    8009d6 <memset+0x3f>
		c &= 0xFF;
  8009b1:	0f b6 7d 0c          	movzbl 0xc(%ebp),%edi
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009b5:	89 fb                	mov    %edi,%ebx
  8009b7:	c1 e3 08             	shl    $0x8,%ebx
  8009ba:	89 fe                	mov    %edi,%esi
  8009bc:	c1 e6 18             	shl    $0x18,%esi
  8009bf:	89 f8                	mov    %edi,%eax
  8009c1:	c1 e0 10             	shl    $0x10,%eax
  8009c4:	09 f0                	or     %esi,%eax
  8009c6:	09 c7                	or     %eax,%edi
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  8009c8:	c1 e9 02             	shr    $0x2,%ecx

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009cb:	89 f8                	mov    %edi,%eax
  8009cd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
  8009cf:	89 d7                	mov    %edx,%edi
  8009d1:	fc                   	cld    
  8009d2:	f3 ab                	rep stos %eax,%es:(%edi)
  8009d4:	eb 08                	jmp    8009de <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009d6:	89 d7                	mov    %edx,%edi
  8009d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009db:	fc                   	cld    
  8009dc:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  8009de:	89 d0                	mov    %edx,%eax
  8009e0:	5b                   	pop    %ebx
  8009e1:	5e                   	pop    %esi
  8009e2:	5f                   	pop    %edi
  8009e3:	5d                   	pop    %ebp
  8009e4:	c3                   	ret    

008009e5 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009e5:	55                   	push   %ebp
  8009e6:	89 e5                	mov    %esp,%ebp
  8009e8:	57                   	push   %edi
  8009e9:	56                   	push   %esi
  8009ea:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ed:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009f3:	39 c6                	cmp    %eax,%esi
  8009f5:	73 35                	jae    800a2c <memmove+0x47>
  8009f7:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009fa:	39 d0                	cmp    %edx,%eax
  8009fc:	73 2e                	jae    800a2c <memmove+0x47>
		s += n;
		d += n;
  8009fe:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a01:	89 d6                	mov    %edx,%esi
  800a03:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a05:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a0b:	75 13                	jne    800a20 <memmove+0x3b>
  800a0d:	f6 c1 03             	test   $0x3,%cl
  800a10:	75 0e                	jne    800a20 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a12:	83 ef 04             	sub    $0x4,%edi
  800a15:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a18:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a1b:	fd                   	std    
  800a1c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a1e:	eb 09                	jmp    800a29 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a20:	83 ef 01             	sub    $0x1,%edi
  800a23:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a26:	fd                   	std    
  800a27:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a29:	fc                   	cld    
  800a2a:	eb 1d                	jmp    800a49 <memmove+0x64>
  800a2c:	89 f2                	mov    %esi,%edx
  800a2e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a30:	f6 c2 03             	test   $0x3,%dl
  800a33:	75 0f                	jne    800a44 <memmove+0x5f>
  800a35:	f6 c1 03             	test   $0x3,%cl
  800a38:	75 0a                	jne    800a44 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a3a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a3d:	89 c7                	mov    %eax,%edi
  800a3f:	fc                   	cld    
  800a40:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a42:	eb 05                	jmp    800a49 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a44:	89 c7                	mov    %eax,%edi
  800a46:	fc                   	cld    
  800a47:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a49:	5e                   	pop    %esi
  800a4a:	5f                   	pop    %edi
  800a4b:	5d                   	pop    %ebp
  800a4c:	c3                   	ret    

00800a4d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a4d:	55                   	push   %ebp
  800a4e:	89 e5                	mov    %esp,%ebp
  800a50:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a53:	8b 45 10             	mov    0x10(%ebp),%eax
  800a56:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a5a:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a5d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a61:	8b 45 08             	mov    0x8(%ebp),%eax
  800a64:	89 04 24             	mov    %eax,(%esp)
  800a67:	e8 79 ff ff ff       	call   8009e5 <memmove>
}
  800a6c:	c9                   	leave  
  800a6d:	c3                   	ret    

00800a6e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a6e:	55                   	push   %ebp
  800a6f:	89 e5                	mov    %esp,%ebp
  800a71:	56                   	push   %esi
  800a72:	53                   	push   %ebx
  800a73:	8b 55 08             	mov    0x8(%ebp),%edx
  800a76:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a79:	89 d6                	mov    %edx,%esi
  800a7b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a7e:	eb 1a                	jmp    800a9a <memcmp+0x2c>
		if (*s1 != *s2)
  800a80:	0f b6 02             	movzbl (%edx),%eax
  800a83:	0f b6 19             	movzbl (%ecx),%ebx
  800a86:	38 d8                	cmp    %bl,%al
  800a88:	74 0a                	je     800a94 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a8a:	0f b6 c0             	movzbl %al,%eax
  800a8d:	0f b6 db             	movzbl %bl,%ebx
  800a90:	29 d8                	sub    %ebx,%eax
  800a92:	eb 0f                	jmp    800aa3 <memcmp+0x35>
		s1++, s2++;
  800a94:	83 c2 01             	add    $0x1,%edx
  800a97:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a9a:	39 f2                	cmp    %esi,%edx
  800a9c:	75 e2                	jne    800a80 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a9e:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800aa3:	5b                   	pop    %ebx
  800aa4:	5e                   	pop    %esi
  800aa5:	5d                   	pop    %ebp
  800aa6:	c3                   	ret    

00800aa7 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800aa7:	55                   	push   %ebp
  800aa8:	89 e5                	mov    %esp,%ebp
  800aaa:	8b 45 08             	mov    0x8(%ebp),%eax
  800aad:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800ab0:	89 c2                	mov    %eax,%edx
  800ab2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ab5:	eb 07                	jmp    800abe <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ab7:	38 08                	cmp    %cl,(%eax)
  800ab9:	74 07                	je     800ac2 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800abb:	83 c0 01             	add    $0x1,%eax
  800abe:	39 d0                	cmp    %edx,%eax
  800ac0:	72 f5                	jb     800ab7 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800ac2:	5d                   	pop    %ebp
  800ac3:	c3                   	ret    

00800ac4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800ac4:	55                   	push   %ebp
  800ac5:	89 e5                	mov    %esp,%ebp
  800ac7:	57                   	push   %edi
  800ac8:	56                   	push   %esi
  800ac9:	53                   	push   %ebx
  800aca:	8b 55 08             	mov    0x8(%ebp),%edx
  800acd:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ad0:	eb 03                	jmp    800ad5 <strtol+0x11>
		s++;
  800ad2:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800ad5:	0f b6 0a             	movzbl (%edx),%ecx
  800ad8:	80 f9 09             	cmp    $0x9,%cl
  800adb:	74 f5                	je     800ad2 <strtol+0xe>
  800add:	80 f9 20             	cmp    $0x20,%cl
  800ae0:	74 f0                	je     800ad2 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ae2:	80 f9 2b             	cmp    $0x2b,%cl
  800ae5:	75 0a                	jne    800af1 <strtol+0x2d>
		s++;
  800ae7:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800aea:	bf 00 00 00 00       	mov    $0x0,%edi
  800aef:	eb 11                	jmp    800b02 <strtol+0x3e>
  800af1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800af6:	80 f9 2d             	cmp    $0x2d,%cl
  800af9:	75 07                	jne    800b02 <strtol+0x3e>
		s++, neg = 1;
  800afb:	8d 52 01             	lea    0x1(%edx),%edx
  800afe:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b02:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b07:	75 15                	jne    800b1e <strtol+0x5a>
  800b09:	80 3a 30             	cmpb   $0x30,(%edx)
  800b0c:	75 10                	jne    800b1e <strtol+0x5a>
  800b0e:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b12:	75 0a                	jne    800b1e <strtol+0x5a>
		s += 2, base = 16;
  800b14:	83 c2 02             	add    $0x2,%edx
  800b17:	b8 10 00 00 00       	mov    $0x10,%eax
  800b1c:	eb 10                	jmp    800b2e <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b1e:	85 c0                	test   %eax,%eax
  800b20:	75 0c                	jne    800b2e <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b22:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b24:	80 3a 30             	cmpb   $0x30,(%edx)
  800b27:	75 05                	jne    800b2e <strtol+0x6a>
		s++, base = 8;
  800b29:	83 c2 01             	add    $0x1,%edx
  800b2c:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b2e:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b33:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b36:	0f b6 0a             	movzbl (%edx),%ecx
  800b39:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b3c:	89 f0                	mov    %esi,%eax
  800b3e:	3c 09                	cmp    $0x9,%al
  800b40:	77 08                	ja     800b4a <strtol+0x86>
			dig = *s - '0';
  800b42:	0f be c9             	movsbl %cl,%ecx
  800b45:	83 e9 30             	sub    $0x30,%ecx
  800b48:	eb 20                	jmp    800b6a <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b4a:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b4d:	89 f0                	mov    %esi,%eax
  800b4f:	3c 19                	cmp    $0x19,%al
  800b51:	77 08                	ja     800b5b <strtol+0x97>
			dig = *s - 'a' + 10;
  800b53:	0f be c9             	movsbl %cl,%ecx
  800b56:	83 e9 57             	sub    $0x57,%ecx
  800b59:	eb 0f                	jmp    800b6a <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b5b:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b5e:	89 f0                	mov    %esi,%eax
  800b60:	3c 19                	cmp    $0x19,%al
  800b62:	77 16                	ja     800b7a <strtol+0xb6>
			dig = *s - 'A' + 10;
  800b64:	0f be c9             	movsbl %cl,%ecx
  800b67:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b6a:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b6d:	7d 0f                	jge    800b7e <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800b6f:	83 c2 01             	add    $0x1,%edx
  800b72:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b76:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b78:	eb bc                	jmp    800b36 <strtol+0x72>
  800b7a:	89 d8                	mov    %ebx,%eax
  800b7c:	eb 02                	jmp    800b80 <strtol+0xbc>
  800b7e:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b80:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b84:	74 05                	je     800b8b <strtol+0xc7>
		*endptr = (char *) s;
  800b86:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b89:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800b8b:	f7 d8                	neg    %eax
  800b8d:	85 ff                	test   %edi,%edi
  800b8f:	0f 44 c3             	cmove  %ebx,%eax
}
  800b92:	5b                   	pop    %ebx
  800b93:	5e                   	pop    %esi
  800b94:	5f                   	pop    %edi
  800b95:	5d                   	pop    %ebp
  800b96:	c3                   	ret    

00800b97 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800b97:	55                   	push   %ebp
  800b98:	89 e5                	mov    %esp,%ebp
  800b9a:	57                   	push   %edi
  800b9b:	56                   	push   %esi
  800b9c:	53                   	push   %ebx
  800b9d:	83 ec 2c             	sub    $0x2c,%esp
  800ba0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800ba3:	89 55 e0             	mov    %edx,-0x20(%ebp)
  800ba6:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ba8:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800bae:	8b 7d 10             	mov    0x10(%ebp),%edi
  800bb1:	8b 75 14             	mov    0x14(%ebp),%esi
  800bb4:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800bb6:	85 c0                	test   %eax,%eax
  800bb8:	7e 2d                	jle    800be7 <syscall+0x50>
  800bba:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800bbe:	74 27                	je     800be7 <syscall+0x50>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bc0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800bc4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800bc7:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bcb:	c7 44 24 08 58 12 80 	movl   $0x801258,0x8(%esp)
  800bd2:	00 
  800bd3:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800bda:	00 
  800bdb:	c7 04 24 75 12 80 00 	movl   $0x801275,(%esp)
  800be2:	e8 60 f5 ff ff       	call   800147 <_panic>

	return ret;
}
  800be7:	83 c4 2c             	add    $0x2c,%esp
  800bea:	5b                   	pop    %ebx
  800beb:	5e                   	pop    %esi
  800bec:	5f                   	pop    %edi
  800bed:	5d                   	pop    %ebp
  800bee:	c3                   	ret    

00800bef <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800bef:	55                   	push   %ebp
  800bf0:	89 e5                	mov    %esp,%ebp
  800bf2:	83 ec 18             	sub    $0x18,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800bf5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800bfc:	00 
  800bfd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800c04:	00 
  800c05:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800c0c:	00 
  800c0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c10:	89 04 24             	mov    %eax,(%esp)
  800c13:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c16:	ba 00 00 00 00       	mov    $0x0,%edx
  800c1b:	b8 00 00 00 00       	mov    $0x0,%eax
  800c20:	e8 72 ff ff ff       	call   800b97 <syscall>
}
  800c25:	c9                   	leave  
  800c26:	c3                   	ret    

00800c27 <sys_cgetc>:

int
sys_cgetc(void)
{
  800c27:	55                   	push   %ebp
  800c28:	89 e5                	mov    %esp,%ebp
  800c2a:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800c2d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800c34:	00 
  800c35:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800c3c:	00 
  800c3d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800c44:	00 
  800c45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800c4c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800c51:	ba 00 00 00 00       	mov    $0x0,%edx
  800c56:	b8 01 00 00 00       	mov    $0x1,%eax
  800c5b:	e8 37 ff ff ff       	call   800b97 <syscall>
}
  800c60:	c9                   	leave  
  800c61:	c3                   	ret    

00800c62 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800c62:	55                   	push   %ebp
  800c63:	89 e5                	mov    %esp,%ebp
  800c65:	83 ec 18             	sub    $0x18,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800c68:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800c6f:	00 
  800c70:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800c77:	00 
  800c78:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800c7f:	00 
  800c80:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800c87:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c8a:	ba 01 00 00 00       	mov    $0x1,%edx
  800c8f:	b8 03 00 00 00       	mov    $0x3,%eax
  800c94:	e8 fe fe ff ff       	call   800b97 <syscall>
}
  800c99:	c9                   	leave  
  800c9a:	c3                   	ret    

00800c9b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800c9b:	55                   	push   %ebp
  800c9c:	89 e5                	mov    %esp,%ebp
  800c9e:	83 ec 18             	sub    $0x18,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800ca1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  800ca8:	00 
  800ca9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  800cb0:	00 
  800cb1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  800cb8:	00 
  800cb9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800cc0:	b9 00 00 00 00       	mov    $0x0,%ecx
  800cc5:	ba 00 00 00 00       	mov    $0x0,%edx
  800cca:	b8 02 00 00 00       	mov    $0x2,%eax
  800ccf:	e8 c3 fe ff ff       	call   800b97 <syscall>
}
  800cd4:	c9                   	leave  
  800cd5:	c3                   	ret    
  800cd6:	66 90                	xchg   %ax,%ax
  800cd8:	66 90                	xchg   %ax,%ax
  800cda:	66 90                	xchg   %ax,%ax
  800cdc:	66 90                	xchg   %ax,%ax
  800cde:	66 90                	xchg   %ax,%ax

00800ce0 <__udivdi3>:
  800ce0:	55                   	push   %ebp
  800ce1:	57                   	push   %edi
  800ce2:	56                   	push   %esi
  800ce3:	83 ec 0c             	sub    $0xc,%esp
  800ce6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800cea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800cee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800cf2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800cf6:	85 c0                	test   %eax,%eax
  800cf8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800cfc:	89 ea                	mov    %ebp,%edx
  800cfe:	89 0c 24             	mov    %ecx,(%esp)
  800d01:	75 2d                	jne    800d30 <__udivdi3+0x50>
  800d03:	39 e9                	cmp    %ebp,%ecx
  800d05:	77 61                	ja     800d68 <__udivdi3+0x88>
  800d07:	85 c9                	test   %ecx,%ecx
  800d09:	89 ce                	mov    %ecx,%esi
  800d0b:	75 0b                	jne    800d18 <__udivdi3+0x38>
  800d0d:	b8 01 00 00 00       	mov    $0x1,%eax
  800d12:	31 d2                	xor    %edx,%edx
  800d14:	f7 f1                	div    %ecx
  800d16:	89 c6                	mov    %eax,%esi
  800d18:	31 d2                	xor    %edx,%edx
  800d1a:	89 e8                	mov    %ebp,%eax
  800d1c:	f7 f6                	div    %esi
  800d1e:	89 c5                	mov    %eax,%ebp
  800d20:	89 f8                	mov    %edi,%eax
  800d22:	f7 f6                	div    %esi
  800d24:	89 ea                	mov    %ebp,%edx
  800d26:	83 c4 0c             	add    $0xc,%esp
  800d29:	5e                   	pop    %esi
  800d2a:	5f                   	pop    %edi
  800d2b:	5d                   	pop    %ebp
  800d2c:	c3                   	ret    
  800d2d:	8d 76 00             	lea    0x0(%esi),%esi
  800d30:	39 e8                	cmp    %ebp,%eax
  800d32:	77 24                	ja     800d58 <__udivdi3+0x78>
  800d34:	0f bd e8             	bsr    %eax,%ebp
  800d37:	83 f5 1f             	xor    $0x1f,%ebp
  800d3a:	75 3c                	jne    800d78 <__udivdi3+0x98>
  800d3c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800d40:	39 34 24             	cmp    %esi,(%esp)
  800d43:	0f 86 9f 00 00 00    	jbe    800de8 <__udivdi3+0x108>
  800d49:	39 d0                	cmp    %edx,%eax
  800d4b:	0f 82 97 00 00 00    	jb     800de8 <__udivdi3+0x108>
  800d51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d58:	31 d2                	xor    %edx,%edx
  800d5a:	31 c0                	xor    %eax,%eax
  800d5c:	83 c4 0c             	add    $0xc,%esp
  800d5f:	5e                   	pop    %esi
  800d60:	5f                   	pop    %edi
  800d61:	5d                   	pop    %ebp
  800d62:	c3                   	ret    
  800d63:	90                   	nop
  800d64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d68:	89 f8                	mov    %edi,%eax
  800d6a:	f7 f1                	div    %ecx
  800d6c:	31 d2                	xor    %edx,%edx
  800d6e:	83 c4 0c             	add    $0xc,%esp
  800d71:	5e                   	pop    %esi
  800d72:	5f                   	pop    %edi
  800d73:	5d                   	pop    %ebp
  800d74:	c3                   	ret    
  800d75:	8d 76 00             	lea    0x0(%esi),%esi
  800d78:	89 e9                	mov    %ebp,%ecx
  800d7a:	8b 3c 24             	mov    (%esp),%edi
  800d7d:	d3 e0                	shl    %cl,%eax
  800d7f:	89 c6                	mov    %eax,%esi
  800d81:	b8 20 00 00 00       	mov    $0x20,%eax
  800d86:	29 e8                	sub    %ebp,%eax
  800d88:	89 c1                	mov    %eax,%ecx
  800d8a:	d3 ef                	shr    %cl,%edi
  800d8c:	89 e9                	mov    %ebp,%ecx
  800d8e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800d92:	8b 3c 24             	mov    (%esp),%edi
  800d95:	09 74 24 08          	or     %esi,0x8(%esp)
  800d99:	89 d6                	mov    %edx,%esi
  800d9b:	d3 e7                	shl    %cl,%edi
  800d9d:	89 c1                	mov    %eax,%ecx
  800d9f:	89 3c 24             	mov    %edi,(%esp)
  800da2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800da6:	d3 ee                	shr    %cl,%esi
  800da8:	89 e9                	mov    %ebp,%ecx
  800daa:	d3 e2                	shl    %cl,%edx
  800dac:	89 c1                	mov    %eax,%ecx
  800dae:	d3 ef                	shr    %cl,%edi
  800db0:	09 d7                	or     %edx,%edi
  800db2:	89 f2                	mov    %esi,%edx
  800db4:	89 f8                	mov    %edi,%eax
  800db6:	f7 74 24 08          	divl   0x8(%esp)
  800dba:	89 d6                	mov    %edx,%esi
  800dbc:	89 c7                	mov    %eax,%edi
  800dbe:	f7 24 24             	mull   (%esp)
  800dc1:	39 d6                	cmp    %edx,%esi
  800dc3:	89 14 24             	mov    %edx,(%esp)
  800dc6:	72 30                	jb     800df8 <__udivdi3+0x118>
  800dc8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800dcc:	89 e9                	mov    %ebp,%ecx
  800dce:	d3 e2                	shl    %cl,%edx
  800dd0:	39 c2                	cmp    %eax,%edx
  800dd2:	73 05                	jae    800dd9 <__udivdi3+0xf9>
  800dd4:	3b 34 24             	cmp    (%esp),%esi
  800dd7:	74 1f                	je     800df8 <__udivdi3+0x118>
  800dd9:	89 f8                	mov    %edi,%eax
  800ddb:	31 d2                	xor    %edx,%edx
  800ddd:	e9 7a ff ff ff       	jmp    800d5c <__udivdi3+0x7c>
  800de2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800de8:	31 d2                	xor    %edx,%edx
  800dea:	b8 01 00 00 00       	mov    $0x1,%eax
  800def:	e9 68 ff ff ff       	jmp    800d5c <__udivdi3+0x7c>
  800df4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800df8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800dfb:	31 d2                	xor    %edx,%edx
  800dfd:	83 c4 0c             	add    $0xc,%esp
  800e00:	5e                   	pop    %esi
  800e01:	5f                   	pop    %edi
  800e02:	5d                   	pop    %ebp
  800e03:	c3                   	ret    
  800e04:	66 90                	xchg   %ax,%ax
  800e06:	66 90                	xchg   %ax,%ax
  800e08:	66 90                	xchg   %ax,%ax
  800e0a:	66 90                	xchg   %ax,%ax
  800e0c:	66 90                	xchg   %ax,%ax
  800e0e:	66 90                	xchg   %ax,%ax

00800e10 <__umoddi3>:
  800e10:	55                   	push   %ebp
  800e11:	57                   	push   %edi
  800e12:	56                   	push   %esi
  800e13:	83 ec 14             	sub    $0x14,%esp
  800e16:	8b 44 24 28          	mov    0x28(%esp),%eax
  800e1a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e1e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800e22:	89 c7                	mov    %eax,%edi
  800e24:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e28:	8b 44 24 30          	mov    0x30(%esp),%eax
  800e2c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800e30:	89 34 24             	mov    %esi,(%esp)
  800e33:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e37:	85 c0                	test   %eax,%eax
  800e39:	89 c2                	mov    %eax,%edx
  800e3b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e3f:	75 17                	jne    800e58 <__umoddi3+0x48>
  800e41:	39 fe                	cmp    %edi,%esi
  800e43:	76 4b                	jbe    800e90 <__umoddi3+0x80>
  800e45:	89 c8                	mov    %ecx,%eax
  800e47:	89 fa                	mov    %edi,%edx
  800e49:	f7 f6                	div    %esi
  800e4b:	89 d0                	mov    %edx,%eax
  800e4d:	31 d2                	xor    %edx,%edx
  800e4f:	83 c4 14             	add    $0x14,%esp
  800e52:	5e                   	pop    %esi
  800e53:	5f                   	pop    %edi
  800e54:	5d                   	pop    %ebp
  800e55:	c3                   	ret    
  800e56:	66 90                	xchg   %ax,%ax
  800e58:	39 f8                	cmp    %edi,%eax
  800e5a:	77 54                	ja     800eb0 <__umoddi3+0xa0>
  800e5c:	0f bd e8             	bsr    %eax,%ebp
  800e5f:	83 f5 1f             	xor    $0x1f,%ebp
  800e62:	75 5c                	jne    800ec0 <__umoddi3+0xb0>
  800e64:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800e68:	39 3c 24             	cmp    %edi,(%esp)
  800e6b:	0f 87 e7 00 00 00    	ja     800f58 <__umoddi3+0x148>
  800e71:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800e75:	29 f1                	sub    %esi,%ecx
  800e77:	19 c7                	sbb    %eax,%edi
  800e79:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e7d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e81:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e85:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800e89:	83 c4 14             	add    $0x14,%esp
  800e8c:	5e                   	pop    %esi
  800e8d:	5f                   	pop    %edi
  800e8e:	5d                   	pop    %ebp
  800e8f:	c3                   	ret    
  800e90:	85 f6                	test   %esi,%esi
  800e92:	89 f5                	mov    %esi,%ebp
  800e94:	75 0b                	jne    800ea1 <__umoddi3+0x91>
  800e96:	b8 01 00 00 00       	mov    $0x1,%eax
  800e9b:	31 d2                	xor    %edx,%edx
  800e9d:	f7 f6                	div    %esi
  800e9f:	89 c5                	mov    %eax,%ebp
  800ea1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800ea5:	31 d2                	xor    %edx,%edx
  800ea7:	f7 f5                	div    %ebp
  800ea9:	89 c8                	mov    %ecx,%eax
  800eab:	f7 f5                	div    %ebp
  800ead:	eb 9c                	jmp    800e4b <__umoddi3+0x3b>
  800eaf:	90                   	nop
  800eb0:	89 c8                	mov    %ecx,%eax
  800eb2:	89 fa                	mov    %edi,%edx
  800eb4:	83 c4 14             	add    $0x14,%esp
  800eb7:	5e                   	pop    %esi
  800eb8:	5f                   	pop    %edi
  800eb9:	5d                   	pop    %ebp
  800eba:	c3                   	ret    
  800ebb:	90                   	nop
  800ebc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ec0:	8b 04 24             	mov    (%esp),%eax
  800ec3:	be 20 00 00 00       	mov    $0x20,%esi
  800ec8:	89 e9                	mov    %ebp,%ecx
  800eca:	29 ee                	sub    %ebp,%esi
  800ecc:	d3 e2                	shl    %cl,%edx
  800ece:	89 f1                	mov    %esi,%ecx
  800ed0:	d3 e8                	shr    %cl,%eax
  800ed2:	89 e9                	mov    %ebp,%ecx
  800ed4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ed8:	8b 04 24             	mov    (%esp),%eax
  800edb:	09 54 24 04          	or     %edx,0x4(%esp)
  800edf:	89 fa                	mov    %edi,%edx
  800ee1:	d3 e0                	shl    %cl,%eax
  800ee3:	89 f1                	mov    %esi,%ecx
  800ee5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ee9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800eed:	d3 ea                	shr    %cl,%edx
  800eef:	89 e9                	mov    %ebp,%ecx
  800ef1:	d3 e7                	shl    %cl,%edi
  800ef3:	89 f1                	mov    %esi,%ecx
  800ef5:	d3 e8                	shr    %cl,%eax
  800ef7:	89 e9                	mov    %ebp,%ecx
  800ef9:	09 f8                	or     %edi,%eax
  800efb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800eff:	f7 74 24 04          	divl   0x4(%esp)
  800f03:	d3 e7                	shl    %cl,%edi
  800f05:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800f09:	89 d7                	mov    %edx,%edi
  800f0b:	f7 64 24 08          	mull   0x8(%esp)
  800f0f:	39 d7                	cmp    %edx,%edi
  800f11:	89 c1                	mov    %eax,%ecx
  800f13:	89 14 24             	mov    %edx,(%esp)
  800f16:	72 2c                	jb     800f44 <__umoddi3+0x134>
  800f18:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800f1c:	72 22                	jb     800f40 <__umoddi3+0x130>
  800f1e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800f22:	29 c8                	sub    %ecx,%eax
  800f24:	19 d7                	sbb    %edx,%edi
  800f26:	89 e9                	mov    %ebp,%ecx
  800f28:	89 fa                	mov    %edi,%edx
  800f2a:	d3 e8                	shr    %cl,%eax
  800f2c:	89 f1                	mov    %esi,%ecx
  800f2e:	d3 e2                	shl    %cl,%edx
  800f30:	89 e9                	mov    %ebp,%ecx
  800f32:	d3 ef                	shr    %cl,%edi
  800f34:	09 d0                	or     %edx,%eax
  800f36:	89 fa                	mov    %edi,%edx
  800f38:	83 c4 14             	add    $0x14,%esp
  800f3b:	5e                   	pop    %esi
  800f3c:	5f                   	pop    %edi
  800f3d:	5d                   	pop    %ebp
  800f3e:	c3                   	ret    
  800f3f:	90                   	nop
  800f40:	39 d7                	cmp    %edx,%edi
  800f42:	75 da                	jne    800f1e <__umoddi3+0x10e>
  800f44:	8b 14 24             	mov    (%esp),%edx
  800f47:	89 c1                	mov    %eax,%ecx
  800f49:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800f4d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800f51:	eb cb                	jmp    800f1e <__umoddi3+0x10e>
  800f53:	90                   	nop
  800f54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f58:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800f5c:	0f 82 0f ff ff ff    	jb     800e71 <__umoddi3+0x61>
  800f62:	e9 1a ff ff ff       	jmp    800e81 <__umoddi3+0x71>
