
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
  800039:	68 60 0f 80 00       	push   $0x800f60
  80003e:	e8 ce 01 00 00       	call   800211 <cprintf>
  800043:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < ARRAYSIZE; i++)
  800046:	b8 00 00 00 00       	mov    $0x0,%eax
		if (bigarray[i] != 0)
  80004b:	83 3c 85 20 20 80 00 	cmpl   $0x0,0x802020(,%eax,4)
  800052:	00 
  800053:	74 12                	je     800067 <umain+0x34>
			panic("bigarray[%d] isn't cleared!\n", i);
  800055:	50                   	push   %eax
  800056:	68 db 0f 80 00       	push   $0x800fdb
  80005b:	6a 11                	push   $0x11
  80005d:	68 f8 0f 80 00       	push   $0x800ff8
  800062:	e8 d1 00 00 00       	call   800138 <_panic>
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
  800096:	68 80 0f 80 00       	push   $0x800f80
  80009b:	6a 16                	push   $0x16
  80009d:	68 f8 0f 80 00       	push   $0x800ff8
  8000a2:	e8 91 00 00 00       	call   800138 <_panic>
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
  8000b4:	68 a8 0f 80 00       	push   $0x800fa8
  8000b9:	e8 53 01 00 00       	call   800211 <cprintf>
	bigarray[ARRAYSIZE+1024] = 0;
  8000be:	c7 05 20 30 c0 00 00 	movl   $0x0,0xc03020
  8000c5:	00 00 00 
	panic("SHOULD HAVE TRAPPED!!!");
  8000c8:	83 c4 0c             	add    $0xc,%esp
  8000cb:	68 07 10 80 00       	push   $0x801007
  8000d0:	6a 1a                	push   $0x1a
  8000d2:	68 f8 0f 80 00       	push   $0x800ff8
  8000d7:	e8 5c 00 00 00       	call   800138 <_panic>

008000dc <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000dc:	55                   	push   %ebp
  8000dd:	89 e5                	mov    %esp,%ebp
  8000df:	56                   	push   %esi
  8000e0:	53                   	push   %ebx
  8000e1:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000e4:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	envid_t id = sys_getenvid();
  8000e7:	e8 8f 0a 00 00       	call   800b7b <sys_getenvid>
	if (id >= 0)
  8000ec:	85 c0                	test   %eax,%eax
  8000ee:	78 12                	js     800102 <libmain+0x26>
		thisenv = &envs[ENVX(id)];
  8000f0:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000f5:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000f8:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000fd:	a3 20 20 c0 00       	mov    %eax,0xc02020

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800102:	85 db                	test   %ebx,%ebx
  800104:	7e 07                	jle    80010d <libmain+0x31>
		binaryname = argv[0];
  800106:	8b 06                	mov    (%esi),%eax
  800108:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80010d:	83 ec 08             	sub    $0x8,%esp
  800110:	56                   	push   %esi
  800111:	53                   	push   %ebx
  800112:	e8 1c ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800117:	e8 0a 00 00 00       	call   800126 <exit>
}
  80011c:	83 c4 10             	add    $0x10,%esp
  80011f:	8d 65 f8             	lea    -0x8(%ebp),%esp
  800122:	5b                   	pop    %ebx
  800123:	5e                   	pop    %esi
  800124:	5d                   	pop    %ebp
  800125:	c3                   	ret    

00800126 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800126:	55                   	push   %ebp
  800127:	89 e5                	mov    %esp,%ebp
  800129:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80012c:	6a 00                	push   $0x0
  80012e:	e8 26 0a 00 00       	call   800b59 <sys_env_destroy>
}
  800133:	83 c4 10             	add    $0x10,%esp
  800136:	c9                   	leave  
  800137:	c3                   	ret    

00800138 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800138:	55                   	push   %ebp
  800139:	89 e5                	mov    %esp,%ebp
  80013b:	56                   	push   %esi
  80013c:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  80013d:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800140:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800146:	e8 30 0a 00 00       	call   800b7b <sys_getenvid>
  80014b:	83 ec 0c             	sub    $0xc,%esp
  80014e:	ff 75 0c             	pushl  0xc(%ebp)
  800151:	ff 75 08             	pushl  0x8(%ebp)
  800154:	56                   	push   %esi
  800155:	50                   	push   %eax
  800156:	68 28 10 80 00       	push   $0x801028
  80015b:	e8 b1 00 00 00       	call   800211 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800160:	83 c4 18             	add    $0x18,%esp
  800163:	53                   	push   %ebx
  800164:	ff 75 10             	pushl  0x10(%ebp)
  800167:	e8 54 00 00 00       	call   8001c0 <vcprintf>
	cprintf("\n");
  80016c:	c7 04 24 f6 0f 80 00 	movl   $0x800ff6,(%esp)
  800173:	e8 99 00 00 00       	call   800211 <cprintf>
  800178:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  80017b:	cc                   	int3   
  80017c:	eb fd                	jmp    80017b <_panic+0x43>

0080017e <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80017e:	55                   	push   %ebp
  80017f:	89 e5                	mov    %esp,%ebp
  800181:	53                   	push   %ebx
  800182:	83 ec 04             	sub    $0x4,%esp
  800185:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800188:	8b 13                	mov    (%ebx),%edx
  80018a:	8d 42 01             	lea    0x1(%edx),%eax
  80018d:	89 03                	mov    %eax,(%ebx)
  80018f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800192:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800196:	3d ff 00 00 00       	cmp    $0xff,%eax
  80019b:	75 1a                	jne    8001b7 <putch+0x39>
		sys_cputs(b->buf, b->idx);
  80019d:	83 ec 08             	sub    $0x8,%esp
  8001a0:	68 ff 00 00 00       	push   $0xff
  8001a5:	8d 43 08             	lea    0x8(%ebx),%eax
  8001a8:	50                   	push   %eax
  8001a9:	e8 61 09 00 00       	call   800b0f <sys_cputs>
		b->idx = 0;
  8001ae:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8001b4:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8001b7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001bb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8001be:	c9                   	leave  
  8001bf:	c3                   	ret    

008001c0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001c0:	55                   	push   %ebp
  8001c1:	89 e5                	mov    %esp,%ebp
  8001c3:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8001c9:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001d0:	00 00 00 
	b.cnt = 0;
  8001d3:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001da:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001dd:	ff 75 0c             	pushl  0xc(%ebp)
  8001e0:	ff 75 08             	pushl  0x8(%ebp)
  8001e3:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001e9:	50                   	push   %eax
  8001ea:	68 7e 01 80 00       	push   $0x80017e
  8001ef:	e8 86 01 00 00       	call   80037a <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001f4:	83 c4 08             	add    $0x8,%esp
  8001f7:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  8001fd:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800203:	50                   	push   %eax
  800204:	e8 06 09 00 00       	call   800b0f <sys_cputs>

	return b.cnt;
}
  800209:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80020f:	c9                   	leave  
  800210:	c3                   	ret    

00800211 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800211:	55                   	push   %ebp
  800212:	89 e5                	mov    %esp,%ebp
  800214:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800217:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80021a:	50                   	push   %eax
  80021b:	ff 75 08             	pushl  0x8(%ebp)
  80021e:	e8 9d ff ff ff       	call   8001c0 <vcprintf>
	va_end(ap);

	return cnt;
}
  800223:	c9                   	leave  
  800224:	c3                   	ret    

00800225 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800225:	55                   	push   %ebp
  800226:	89 e5                	mov    %esp,%ebp
  800228:	57                   	push   %edi
  800229:	56                   	push   %esi
  80022a:	53                   	push   %ebx
  80022b:	83 ec 1c             	sub    $0x1c,%esp
  80022e:	89 c7                	mov    %eax,%edi
  800230:	89 d6                	mov    %edx,%esi
  800232:	8b 45 08             	mov    0x8(%ebp),%eax
  800235:	8b 55 0c             	mov    0xc(%ebp),%edx
  800238:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80023b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  80023e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800241:	bb 00 00 00 00       	mov    $0x0,%ebx
  800246:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800249:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  80024c:	39 d3                	cmp    %edx,%ebx
  80024e:	72 05                	jb     800255 <printnum+0x30>
  800250:	39 45 10             	cmp    %eax,0x10(%ebp)
  800253:	77 45                	ja     80029a <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800255:	83 ec 0c             	sub    $0xc,%esp
  800258:	ff 75 18             	pushl  0x18(%ebp)
  80025b:	8b 45 14             	mov    0x14(%ebp),%eax
  80025e:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800261:	53                   	push   %ebx
  800262:	ff 75 10             	pushl  0x10(%ebp)
  800265:	83 ec 08             	sub    $0x8,%esp
  800268:	ff 75 e4             	pushl  -0x1c(%ebp)
  80026b:	ff 75 e0             	pushl  -0x20(%ebp)
  80026e:	ff 75 dc             	pushl  -0x24(%ebp)
  800271:	ff 75 d8             	pushl  -0x28(%ebp)
  800274:	e8 47 0a 00 00       	call   800cc0 <__udivdi3>
  800279:	83 c4 18             	add    $0x18,%esp
  80027c:	52                   	push   %edx
  80027d:	50                   	push   %eax
  80027e:	89 f2                	mov    %esi,%edx
  800280:	89 f8                	mov    %edi,%eax
  800282:	e8 9e ff ff ff       	call   800225 <printnum>
  800287:	83 c4 20             	add    $0x20,%esp
  80028a:	eb 18                	jmp    8002a4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  80028c:	83 ec 08             	sub    $0x8,%esp
  80028f:	56                   	push   %esi
  800290:	ff 75 18             	pushl  0x18(%ebp)
  800293:	ff d7                	call   *%edi
  800295:	83 c4 10             	add    $0x10,%esp
  800298:	eb 03                	jmp    80029d <printnum+0x78>
  80029a:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  80029d:	83 eb 01             	sub    $0x1,%ebx
  8002a0:	85 db                	test   %ebx,%ebx
  8002a2:	7f e8                	jg     80028c <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002a4:	83 ec 08             	sub    $0x8,%esp
  8002a7:	56                   	push   %esi
  8002a8:	83 ec 04             	sub    $0x4,%esp
  8002ab:	ff 75 e4             	pushl  -0x1c(%ebp)
  8002ae:	ff 75 e0             	pushl  -0x20(%ebp)
  8002b1:	ff 75 dc             	pushl  -0x24(%ebp)
  8002b4:	ff 75 d8             	pushl  -0x28(%ebp)
  8002b7:	e8 34 0b 00 00       	call   800df0 <__umoddi3>
  8002bc:	83 c4 14             	add    $0x14,%esp
  8002bf:	0f be 80 4c 10 80 00 	movsbl 0x80104c(%eax),%eax
  8002c6:	50                   	push   %eax
  8002c7:	ff d7                	call   *%edi
}
  8002c9:	83 c4 10             	add    $0x10,%esp
  8002cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8002cf:	5b                   	pop    %ebx
  8002d0:	5e                   	pop    %esi
  8002d1:	5f                   	pop    %edi
  8002d2:	5d                   	pop    %ebp
  8002d3:	c3                   	ret    

008002d4 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002d4:	55                   	push   %ebp
  8002d5:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002d7:	83 fa 01             	cmp    $0x1,%edx
  8002da:	7e 0e                	jle    8002ea <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002dc:	8b 10                	mov    (%eax),%edx
  8002de:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002e1:	89 08                	mov    %ecx,(%eax)
  8002e3:	8b 02                	mov    (%edx),%eax
  8002e5:	8b 52 04             	mov    0x4(%edx),%edx
  8002e8:	eb 22                	jmp    80030c <getuint+0x38>
	else if (lflag)
  8002ea:	85 d2                	test   %edx,%edx
  8002ec:	74 10                	je     8002fe <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002ee:	8b 10                	mov    (%eax),%edx
  8002f0:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002f3:	89 08                	mov    %ecx,(%eax)
  8002f5:	8b 02                	mov    (%edx),%eax
  8002f7:	ba 00 00 00 00       	mov    $0x0,%edx
  8002fc:	eb 0e                	jmp    80030c <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002fe:	8b 10                	mov    (%eax),%edx
  800300:	8d 4a 04             	lea    0x4(%edx),%ecx
  800303:	89 08                	mov    %ecx,(%eax)
  800305:	8b 02                	mov    (%edx),%eax
  800307:	ba 00 00 00 00       	mov    $0x0,%edx
}
  80030c:	5d                   	pop    %ebp
  80030d:	c3                   	ret    

0080030e <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  80030e:	55                   	push   %ebp
  80030f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800311:	83 fa 01             	cmp    $0x1,%edx
  800314:	7e 0e                	jle    800324 <getint+0x16>
		return va_arg(*ap, long long);
  800316:	8b 10                	mov    (%eax),%edx
  800318:	8d 4a 08             	lea    0x8(%edx),%ecx
  80031b:	89 08                	mov    %ecx,(%eax)
  80031d:	8b 02                	mov    (%edx),%eax
  80031f:	8b 52 04             	mov    0x4(%edx),%edx
  800322:	eb 1a                	jmp    80033e <getint+0x30>
	else if (lflag)
  800324:	85 d2                	test   %edx,%edx
  800326:	74 0c                	je     800334 <getint+0x26>
		return va_arg(*ap, long);
  800328:	8b 10                	mov    (%eax),%edx
  80032a:	8d 4a 04             	lea    0x4(%edx),%ecx
  80032d:	89 08                	mov    %ecx,(%eax)
  80032f:	8b 02                	mov    (%edx),%eax
  800331:	99                   	cltd   
  800332:	eb 0a                	jmp    80033e <getint+0x30>
	else
		return va_arg(*ap, int);
  800334:	8b 10                	mov    (%eax),%edx
  800336:	8d 4a 04             	lea    0x4(%edx),%ecx
  800339:	89 08                	mov    %ecx,(%eax)
  80033b:	8b 02                	mov    (%edx),%eax
  80033d:	99                   	cltd   
}
  80033e:	5d                   	pop    %ebp
  80033f:	c3                   	ret    

00800340 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800340:	55                   	push   %ebp
  800341:	89 e5                	mov    %esp,%ebp
  800343:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  800346:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  80034a:	8b 10                	mov    (%eax),%edx
  80034c:	3b 50 04             	cmp    0x4(%eax),%edx
  80034f:	73 0a                	jae    80035b <sprintputch+0x1b>
		*b->buf++ = ch;
  800351:	8d 4a 01             	lea    0x1(%edx),%ecx
  800354:	89 08                	mov    %ecx,(%eax)
  800356:	8b 45 08             	mov    0x8(%ebp),%eax
  800359:	88 02                	mov    %al,(%edx)
}
  80035b:	5d                   	pop    %ebp
  80035c:	c3                   	ret    

0080035d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  80035d:	55                   	push   %ebp
  80035e:	89 e5                	mov    %esp,%ebp
  800360:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  800363:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  800366:	50                   	push   %eax
  800367:	ff 75 10             	pushl  0x10(%ebp)
  80036a:	ff 75 0c             	pushl  0xc(%ebp)
  80036d:	ff 75 08             	pushl  0x8(%ebp)
  800370:	e8 05 00 00 00       	call   80037a <vprintfmt>
	va_end(ap);
}
  800375:	83 c4 10             	add    $0x10,%esp
  800378:	c9                   	leave  
  800379:	c3                   	ret    

0080037a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80037a:	55                   	push   %ebp
  80037b:	89 e5                	mov    %esp,%ebp
  80037d:	57                   	push   %edi
  80037e:	56                   	push   %esi
  80037f:	53                   	push   %ebx
  800380:	83 ec 2c             	sub    $0x2c,%esp
  800383:	8b 75 08             	mov    0x8(%ebp),%esi
  800386:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800389:	8b 7d 10             	mov    0x10(%ebp),%edi
  80038c:	eb 12                	jmp    8003a0 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80038e:	85 c0                	test   %eax,%eax
  800390:	0f 84 44 03 00 00    	je     8006da <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  800396:	83 ec 08             	sub    $0x8,%esp
  800399:	53                   	push   %ebx
  80039a:	50                   	push   %eax
  80039b:	ff d6                	call   *%esi
  80039d:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003a0:	83 c7 01             	add    $0x1,%edi
  8003a3:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8003a7:	83 f8 25             	cmp    $0x25,%eax
  8003aa:	75 e2                	jne    80038e <vprintfmt+0x14>
  8003ac:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8003b0:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8003b7:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8003be:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8003c5:	ba 00 00 00 00       	mov    $0x0,%edx
  8003ca:	eb 07                	jmp    8003d3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003cf:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d3:	8d 47 01             	lea    0x1(%edi),%eax
  8003d6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003d9:	0f b6 07             	movzbl (%edi),%eax
  8003dc:	0f b6 c8             	movzbl %al,%ecx
  8003df:	83 e8 23             	sub    $0x23,%eax
  8003e2:	3c 55                	cmp    $0x55,%al
  8003e4:	0f 87 d5 02 00 00    	ja     8006bf <vprintfmt+0x345>
  8003ea:	0f b6 c0             	movzbl %al,%eax
  8003ed:	ff 24 85 20 11 80 00 	jmp    *0x801120(,%eax,4)
  8003f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003f7:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  8003fb:	eb d6                	jmp    8003d3 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003fd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800400:	b8 00 00 00 00       	mov    $0x0,%eax
  800405:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800408:	8d 04 80             	lea    (%eax,%eax,4),%eax
  80040b:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  80040f:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  800412:	8d 51 d0             	lea    -0x30(%ecx),%edx
  800415:	83 fa 09             	cmp    $0x9,%edx
  800418:	77 39                	ja     800453 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  80041a:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80041d:	eb e9                	jmp    800408 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  80041f:	8b 45 14             	mov    0x14(%ebp),%eax
  800422:	8d 48 04             	lea    0x4(%eax),%ecx
  800425:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800428:	8b 00                	mov    (%eax),%eax
  80042a:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80042d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800430:	eb 27                	jmp    800459 <vprintfmt+0xdf>
  800432:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800435:	85 c0                	test   %eax,%eax
  800437:	b9 00 00 00 00       	mov    $0x0,%ecx
  80043c:	0f 49 c8             	cmovns %eax,%ecx
  80043f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800442:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800445:	eb 8c                	jmp    8003d3 <vprintfmt+0x59>
  800447:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  80044a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800451:	eb 80                	jmp    8003d3 <vprintfmt+0x59>
  800453:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800456:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800459:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80045d:	0f 89 70 ff ff ff    	jns    8003d3 <vprintfmt+0x59>
				width = precision, precision = -1;
  800463:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800466:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800469:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800470:	e9 5e ff ff ff       	jmp    8003d3 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800475:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800478:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80047b:	e9 53 ff ff ff       	jmp    8003d3 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800480:	8b 45 14             	mov    0x14(%ebp),%eax
  800483:	8d 50 04             	lea    0x4(%eax),%edx
  800486:	89 55 14             	mov    %edx,0x14(%ebp)
  800489:	83 ec 08             	sub    $0x8,%esp
  80048c:	53                   	push   %ebx
  80048d:	ff 30                	pushl  (%eax)
  80048f:	ff d6                	call   *%esi
			break;
  800491:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800494:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  800497:	e9 04 ff ff ff       	jmp    8003a0 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80049c:	8b 45 14             	mov    0x14(%ebp),%eax
  80049f:	8d 50 04             	lea    0x4(%eax),%edx
  8004a2:	89 55 14             	mov    %edx,0x14(%ebp)
  8004a5:	8b 00                	mov    (%eax),%eax
  8004a7:	99                   	cltd   
  8004a8:	31 d0                	xor    %edx,%eax
  8004aa:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004ac:	83 f8 08             	cmp    $0x8,%eax
  8004af:	7f 0b                	jg     8004bc <vprintfmt+0x142>
  8004b1:	8b 14 85 80 12 80 00 	mov    0x801280(,%eax,4),%edx
  8004b8:	85 d2                	test   %edx,%edx
  8004ba:	75 18                	jne    8004d4 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8004bc:	50                   	push   %eax
  8004bd:	68 64 10 80 00       	push   $0x801064
  8004c2:	53                   	push   %ebx
  8004c3:	56                   	push   %esi
  8004c4:	e8 94 fe ff ff       	call   80035d <printfmt>
  8004c9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8004cf:	e9 cc fe ff ff       	jmp    8003a0 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8004d4:	52                   	push   %edx
  8004d5:	68 6d 10 80 00       	push   $0x80106d
  8004da:	53                   	push   %ebx
  8004db:	56                   	push   %esi
  8004dc:	e8 7c fe ff ff       	call   80035d <printfmt>
  8004e1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8004e7:	e9 b4 fe ff ff       	jmp    8003a0 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004ec:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ef:	8d 50 04             	lea    0x4(%eax),%edx
  8004f2:	89 55 14             	mov    %edx,0x14(%ebp)
  8004f5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  8004f7:	85 ff                	test   %edi,%edi
  8004f9:	b8 5d 10 80 00       	mov    $0x80105d,%eax
  8004fe:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800501:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800505:	0f 8e 94 00 00 00    	jle    80059f <vprintfmt+0x225>
  80050b:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  80050f:	0f 84 98 00 00 00    	je     8005ad <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  800515:	83 ec 08             	sub    $0x8,%esp
  800518:	ff 75 d0             	pushl  -0x30(%ebp)
  80051b:	57                   	push   %edi
  80051c:	e8 41 02 00 00       	call   800762 <strnlen>
  800521:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  800524:	29 c1                	sub    %eax,%ecx
  800526:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800529:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  80052c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800530:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800533:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  800536:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800538:	eb 0f                	jmp    800549 <vprintfmt+0x1cf>
					putch(padc, putdat);
  80053a:	83 ec 08             	sub    $0x8,%esp
  80053d:	53                   	push   %ebx
  80053e:	ff 75 e0             	pushl  -0x20(%ebp)
  800541:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800543:	83 ef 01             	sub    $0x1,%edi
  800546:	83 c4 10             	add    $0x10,%esp
  800549:	85 ff                	test   %edi,%edi
  80054b:	7f ed                	jg     80053a <vprintfmt+0x1c0>
  80054d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800550:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  800553:	85 c9                	test   %ecx,%ecx
  800555:	b8 00 00 00 00       	mov    $0x0,%eax
  80055a:	0f 49 c1             	cmovns %ecx,%eax
  80055d:	29 c1                	sub    %eax,%ecx
  80055f:	89 75 08             	mov    %esi,0x8(%ebp)
  800562:	8b 75 d0             	mov    -0x30(%ebp),%esi
  800565:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800568:	89 cb                	mov    %ecx,%ebx
  80056a:	eb 4d                	jmp    8005b9 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  80056c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800570:	74 1b                	je     80058d <vprintfmt+0x213>
  800572:	0f be c0             	movsbl %al,%eax
  800575:	83 e8 20             	sub    $0x20,%eax
  800578:	83 f8 5e             	cmp    $0x5e,%eax
  80057b:	76 10                	jbe    80058d <vprintfmt+0x213>
					putch('?', putdat);
  80057d:	83 ec 08             	sub    $0x8,%esp
  800580:	ff 75 0c             	pushl  0xc(%ebp)
  800583:	6a 3f                	push   $0x3f
  800585:	ff 55 08             	call   *0x8(%ebp)
  800588:	83 c4 10             	add    $0x10,%esp
  80058b:	eb 0d                	jmp    80059a <vprintfmt+0x220>
				else
					putch(ch, putdat);
  80058d:	83 ec 08             	sub    $0x8,%esp
  800590:	ff 75 0c             	pushl  0xc(%ebp)
  800593:	52                   	push   %edx
  800594:	ff 55 08             	call   *0x8(%ebp)
  800597:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80059a:	83 eb 01             	sub    $0x1,%ebx
  80059d:	eb 1a                	jmp    8005b9 <vprintfmt+0x23f>
  80059f:	89 75 08             	mov    %esi,0x8(%ebp)
  8005a2:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005a5:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005a8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005ab:	eb 0c                	jmp    8005b9 <vprintfmt+0x23f>
  8005ad:	89 75 08             	mov    %esi,0x8(%ebp)
  8005b0:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8005b3:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8005b6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8005b9:	83 c7 01             	add    $0x1,%edi
  8005bc:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8005c0:	0f be d0             	movsbl %al,%edx
  8005c3:	85 d2                	test   %edx,%edx
  8005c5:	74 23                	je     8005ea <vprintfmt+0x270>
  8005c7:	85 f6                	test   %esi,%esi
  8005c9:	78 a1                	js     80056c <vprintfmt+0x1f2>
  8005cb:	83 ee 01             	sub    $0x1,%esi
  8005ce:	79 9c                	jns    80056c <vprintfmt+0x1f2>
  8005d0:	89 df                	mov    %ebx,%edi
  8005d2:	8b 75 08             	mov    0x8(%ebp),%esi
  8005d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005d8:	eb 18                	jmp    8005f2 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005da:	83 ec 08             	sub    $0x8,%esp
  8005dd:	53                   	push   %ebx
  8005de:	6a 20                	push   $0x20
  8005e0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005e2:	83 ef 01             	sub    $0x1,%edi
  8005e5:	83 c4 10             	add    $0x10,%esp
  8005e8:	eb 08                	jmp    8005f2 <vprintfmt+0x278>
  8005ea:	89 df                	mov    %ebx,%edi
  8005ec:	8b 75 08             	mov    0x8(%ebp),%esi
  8005ef:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8005f2:	85 ff                	test   %edi,%edi
  8005f4:	7f e4                	jg     8005da <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005f6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005f9:	e9 a2 fd ff ff       	jmp    8003a0 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005fe:	8d 45 14             	lea    0x14(%ebp),%eax
  800601:	e8 08 fd ff ff       	call   80030e <getint>
  800606:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800609:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  80060c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800611:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800615:	79 74                	jns    80068b <vprintfmt+0x311>
				putch('-', putdat);
  800617:	83 ec 08             	sub    $0x8,%esp
  80061a:	53                   	push   %ebx
  80061b:	6a 2d                	push   $0x2d
  80061d:	ff d6                	call   *%esi
				num = -(long long) num;
  80061f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800622:	8b 55 dc             	mov    -0x24(%ebp),%edx
  800625:	f7 d8                	neg    %eax
  800627:	83 d2 00             	adc    $0x0,%edx
  80062a:	f7 da                	neg    %edx
  80062c:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  80062f:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800634:	eb 55                	jmp    80068b <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800636:	8d 45 14             	lea    0x14(%ebp),%eax
  800639:	e8 96 fc ff ff       	call   8002d4 <getuint>
			base = 10;
  80063e:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800643:	eb 46                	jmp    80068b <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800645:	8d 45 14             	lea    0x14(%ebp),%eax
  800648:	e8 87 fc ff ff       	call   8002d4 <getuint>
			base = 8;
  80064d:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800652:	eb 37                	jmp    80068b <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  800654:	83 ec 08             	sub    $0x8,%esp
  800657:	53                   	push   %ebx
  800658:	6a 30                	push   $0x30
  80065a:	ff d6                	call   *%esi
			putch('x', putdat);
  80065c:	83 c4 08             	add    $0x8,%esp
  80065f:	53                   	push   %ebx
  800660:	6a 78                	push   $0x78
  800662:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  800664:	8b 45 14             	mov    0x14(%ebp),%eax
  800667:	8d 50 04             	lea    0x4(%eax),%edx
  80066a:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  80066d:	8b 00                	mov    (%eax),%eax
  80066f:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  800674:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  800677:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  80067c:	eb 0d                	jmp    80068b <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  80067e:	8d 45 14             	lea    0x14(%ebp),%eax
  800681:	e8 4e fc ff ff       	call   8002d4 <getuint>
			base = 16;
  800686:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  80068b:	83 ec 0c             	sub    $0xc,%esp
  80068e:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  800692:	57                   	push   %edi
  800693:	ff 75 e0             	pushl  -0x20(%ebp)
  800696:	51                   	push   %ecx
  800697:	52                   	push   %edx
  800698:	50                   	push   %eax
  800699:	89 da                	mov    %ebx,%edx
  80069b:	89 f0                	mov    %esi,%eax
  80069d:	e8 83 fb ff ff       	call   800225 <printnum>
			break;
  8006a2:	83 c4 20             	add    $0x20,%esp
  8006a5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8006a8:	e9 f3 fc ff ff       	jmp    8003a0 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006ad:	83 ec 08             	sub    $0x8,%esp
  8006b0:	53                   	push   %ebx
  8006b1:	51                   	push   %ecx
  8006b2:	ff d6                	call   *%esi
			break;
  8006b4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8006ba:	e9 e1 fc ff ff       	jmp    8003a0 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006bf:	83 ec 08             	sub    $0x8,%esp
  8006c2:	53                   	push   %ebx
  8006c3:	6a 25                	push   $0x25
  8006c5:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006c7:	83 c4 10             	add    $0x10,%esp
  8006ca:	eb 03                	jmp    8006cf <vprintfmt+0x355>
  8006cc:	83 ef 01             	sub    $0x1,%edi
  8006cf:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8006d3:	75 f7                	jne    8006cc <vprintfmt+0x352>
  8006d5:	e9 c6 fc ff ff       	jmp    8003a0 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  8006da:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8006dd:	5b                   	pop    %ebx
  8006de:	5e                   	pop    %esi
  8006df:	5f                   	pop    %edi
  8006e0:	5d                   	pop    %ebp
  8006e1:	c3                   	ret    

008006e2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006e2:	55                   	push   %ebp
  8006e3:	89 e5                	mov    %esp,%ebp
  8006e5:	83 ec 18             	sub    $0x18,%esp
  8006e8:	8b 45 08             	mov    0x8(%ebp),%eax
  8006eb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006ee:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006f1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006f5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006ff:	85 c0                	test   %eax,%eax
  800701:	74 26                	je     800729 <vsnprintf+0x47>
  800703:	85 d2                	test   %edx,%edx
  800705:	7e 22                	jle    800729 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800707:	ff 75 14             	pushl  0x14(%ebp)
  80070a:	ff 75 10             	pushl  0x10(%ebp)
  80070d:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800710:	50                   	push   %eax
  800711:	68 40 03 80 00       	push   $0x800340
  800716:	e8 5f fc ff ff       	call   80037a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80071b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80071e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800721:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800724:	83 c4 10             	add    $0x10,%esp
  800727:	eb 05                	jmp    80072e <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800729:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80072e:	c9                   	leave  
  80072f:	c3                   	ret    

00800730 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800730:	55                   	push   %ebp
  800731:	89 e5                	mov    %esp,%ebp
  800733:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800736:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800739:	50                   	push   %eax
  80073a:	ff 75 10             	pushl  0x10(%ebp)
  80073d:	ff 75 0c             	pushl  0xc(%ebp)
  800740:	ff 75 08             	pushl  0x8(%ebp)
  800743:	e8 9a ff ff ff       	call   8006e2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800748:	c9                   	leave  
  800749:	c3                   	ret    

0080074a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  80074a:	55                   	push   %ebp
  80074b:	89 e5                	mov    %esp,%ebp
  80074d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800750:	b8 00 00 00 00       	mov    $0x0,%eax
  800755:	eb 03                	jmp    80075a <strlen+0x10>
		n++;
  800757:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  80075a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  80075e:	75 f7                	jne    800757 <strlen+0xd>
		n++;
	return n;
}
  800760:	5d                   	pop    %ebp
  800761:	c3                   	ret    

00800762 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800762:	55                   	push   %ebp
  800763:	89 e5                	mov    %esp,%ebp
  800765:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800768:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80076b:	ba 00 00 00 00       	mov    $0x0,%edx
  800770:	eb 03                	jmp    800775 <strnlen+0x13>
		n++;
  800772:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800775:	39 c2                	cmp    %eax,%edx
  800777:	74 08                	je     800781 <strnlen+0x1f>
  800779:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  80077d:	75 f3                	jne    800772 <strnlen+0x10>
  80077f:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  800781:	5d                   	pop    %ebp
  800782:	c3                   	ret    

00800783 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800783:	55                   	push   %ebp
  800784:	89 e5                	mov    %esp,%ebp
  800786:	53                   	push   %ebx
  800787:	8b 45 08             	mov    0x8(%ebp),%eax
  80078a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  80078d:	89 c2                	mov    %eax,%edx
  80078f:	83 c2 01             	add    $0x1,%edx
  800792:	83 c1 01             	add    $0x1,%ecx
  800795:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800799:	88 5a ff             	mov    %bl,-0x1(%edx)
  80079c:	84 db                	test   %bl,%bl
  80079e:	75 ef                	jne    80078f <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007a0:	5b                   	pop    %ebx
  8007a1:	5d                   	pop    %ebp
  8007a2:	c3                   	ret    

008007a3 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007a3:	55                   	push   %ebp
  8007a4:	89 e5                	mov    %esp,%ebp
  8007a6:	53                   	push   %ebx
  8007a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007aa:	53                   	push   %ebx
  8007ab:	e8 9a ff ff ff       	call   80074a <strlen>
  8007b0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8007b3:	ff 75 0c             	pushl  0xc(%ebp)
  8007b6:	01 d8                	add    %ebx,%eax
  8007b8:	50                   	push   %eax
  8007b9:	e8 c5 ff ff ff       	call   800783 <strcpy>
	return dst;
}
  8007be:	89 d8                	mov    %ebx,%eax
  8007c0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8007c3:	c9                   	leave  
  8007c4:	c3                   	ret    

008007c5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007c5:	55                   	push   %ebp
  8007c6:	89 e5                	mov    %esp,%ebp
  8007c8:	56                   	push   %esi
  8007c9:	53                   	push   %ebx
  8007ca:	8b 75 08             	mov    0x8(%ebp),%esi
  8007cd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007d0:	89 f3                	mov    %esi,%ebx
  8007d2:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007d5:	89 f2                	mov    %esi,%edx
  8007d7:	eb 0f                	jmp    8007e8 <strncpy+0x23>
		*dst++ = *src;
  8007d9:	83 c2 01             	add    $0x1,%edx
  8007dc:	0f b6 01             	movzbl (%ecx),%eax
  8007df:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007e2:	80 39 01             	cmpb   $0x1,(%ecx)
  8007e5:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e8:	39 da                	cmp    %ebx,%edx
  8007ea:	75 ed                	jne    8007d9 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007ec:	89 f0                	mov    %esi,%eax
  8007ee:	5b                   	pop    %ebx
  8007ef:	5e                   	pop    %esi
  8007f0:	5d                   	pop    %ebp
  8007f1:	c3                   	ret    

008007f2 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007f2:	55                   	push   %ebp
  8007f3:	89 e5                	mov    %esp,%ebp
  8007f5:	56                   	push   %esi
  8007f6:	53                   	push   %ebx
  8007f7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007fa:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007fd:	8b 55 10             	mov    0x10(%ebp),%edx
  800800:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800802:	85 d2                	test   %edx,%edx
  800804:	74 21                	je     800827 <strlcpy+0x35>
  800806:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  80080a:	89 f2                	mov    %esi,%edx
  80080c:	eb 09                	jmp    800817 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  80080e:	83 c2 01             	add    $0x1,%edx
  800811:	83 c1 01             	add    $0x1,%ecx
  800814:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800817:	39 c2                	cmp    %eax,%edx
  800819:	74 09                	je     800824 <strlcpy+0x32>
  80081b:	0f b6 19             	movzbl (%ecx),%ebx
  80081e:	84 db                	test   %bl,%bl
  800820:	75 ec                	jne    80080e <strlcpy+0x1c>
  800822:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  800824:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  800827:	29 f0                	sub    %esi,%eax
}
  800829:	5b                   	pop    %ebx
  80082a:	5e                   	pop    %esi
  80082b:	5d                   	pop    %ebp
  80082c:	c3                   	ret    

0080082d <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80082d:	55                   	push   %ebp
  80082e:	89 e5                	mov    %esp,%ebp
  800830:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800833:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800836:	eb 06                	jmp    80083e <strcmp+0x11>
		p++, q++;
  800838:	83 c1 01             	add    $0x1,%ecx
  80083b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80083e:	0f b6 01             	movzbl (%ecx),%eax
  800841:	84 c0                	test   %al,%al
  800843:	74 04                	je     800849 <strcmp+0x1c>
  800845:	3a 02                	cmp    (%edx),%al
  800847:	74 ef                	je     800838 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800849:	0f b6 c0             	movzbl %al,%eax
  80084c:	0f b6 12             	movzbl (%edx),%edx
  80084f:	29 d0                	sub    %edx,%eax
}
  800851:	5d                   	pop    %ebp
  800852:	c3                   	ret    

00800853 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800853:	55                   	push   %ebp
  800854:	89 e5                	mov    %esp,%ebp
  800856:	53                   	push   %ebx
  800857:	8b 45 08             	mov    0x8(%ebp),%eax
  80085a:	8b 55 0c             	mov    0xc(%ebp),%edx
  80085d:	89 c3                	mov    %eax,%ebx
  80085f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800862:	eb 06                	jmp    80086a <strncmp+0x17>
		n--, p++, q++;
  800864:	83 c0 01             	add    $0x1,%eax
  800867:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  80086a:	39 d8                	cmp    %ebx,%eax
  80086c:	74 15                	je     800883 <strncmp+0x30>
  80086e:	0f b6 08             	movzbl (%eax),%ecx
  800871:	84 c9                	test   %cl,%cl
  800873:	74 04                	je     800879 <strncmp+0x26>
  800875:	3a 0a                	cmp    (%edx),%cl
  800877:	74 eb                	je     800864 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800879:	0f b6 00             	movzbl (%eax),%eax
  80087c:	0f b6 12             	movzbl (%edx),%edx
  80087f:	29 d0                	sub    %edx,%eax
  800881:	eb 05                	jmp    800888 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800883:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800888:	5b                   	pop    %ebx
  800889:	5d                   	pop    %ebp
  80088a:	c3                   	ret    

0080088b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80088b:	55                   	push   %ebp
  80088c:	89 e5                	mov    %esp,%ebp
  80088e:	8b 45 08             	mov    0x8(%ebp),%eax
  800891:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800895:	eb 07                	jmp    80089e <strchr+0x13>
		if (*s == c)
  800897:	38 ca                	cmp    %cl,%dl
  800899:	74 0f                	je     8008aa <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80089b:	83 c0 01             	add    $0x1,%eax
  80089e:	0f b6 10             	movzbl (%eax),%edx
  8008a1:	84 d2                	test   %dl,%dl
  8008a3:	75 f2                	jne    800897 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008a5:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008aa:	5d                   	pop    %ebp
  8008ab:	c3                   	ret    

008008ac <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008ac:	55                   	push   %ebp
  8008ad:	89 e5                	mov    %esp,%ebp
  8008af:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b6:	eb 03                	jmp    8008bb <strfind+0xf>
  8008b8:	83 c0 01             	add    $0x1,%eax
  8008bb:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8008be:	38 ca                	cmp    %cl,%dl
  8008c0:	74 04                	je     8008c6 <strfind+0x1a>
  8008c2:	84 d2                	test   %dl,%dl
  8008c4:	75 f2                	jne    8008b8 <strfind+0xc>
			break;
	return (char *) s;
}
  8008c6:	5d                   	pop    %ebp
  8008c7:	c3                   	ret    

008008c8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008c8:	55                   	push   %ebp
  8008c9:	89 e5                	mov    %esp,%ebp
  8008cb:	57                   	push   %edi
  8008cc:	56                   	push   %esi
  8008cd:	53                   	push   %ebx
  8008ce:	8b 55 08             	mov    0x8(%ebp),%edx
  8008d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8008d4:	85 c9                	test   %ecx,%ecx
  8008d6:	74 37                	je     80090f <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008d8:	f6 c2 03             	test   $0x3,%dl
  8008db:	75 2a                	jne    800907 <memset+0x3f>
  8008dd:	f6 c1 03             	test   $0x3,%cl
  8008e0:	75 25                	jne    800907 <memset+0x3f>
		c &= 0xFF;
  8008e2:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008e6:	89 df                	mov    %ebx,%edi
  8008e8:	c1 e7 08             	shl    $0x8,%edi
  8008eb:	89 de                	mov    %ebx,%esi
  8008ed:	c1 e6 18             	shl    $0x18,%esi
  8008f0:	89 d8                	mov    %ebx,%eax
  8008f2:	c1 e0 10             	shl    $0x10,%eax
  8008f5:	09 f0                	or     %esi,%eax
  8008f7:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  8008f9:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8008fc:	89 f8                	mov    %edi,%eax
  8008fe:	09 d8                	or     %ebx,%eax
  800900:	89 d7                	mov    %edx,%edi
  800902:	fc                   	cld    
  800903:	f3 ab                	rep stos %eax,%es:(%edi)
  800905:	eb 08                	jmp    80090f <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800907:	89 d7                	mov    %edx,%edi
  800909:	8b 45 0c             	mov    0xc(%ebp),%eax
  80090c:	fc                   	cld    
  80090d:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  80090f:	89 d0                	mov    %edx,%eax
  800911:	5b                   	pop    %ebx
  800912:	5e                   	pop    %esi
  800913:	5f                   	pop    %edi
  800914:	5d                   	pop    %ebp
  800915:	c3                   	ret    

00800916 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800916:	55                   	push   %ebp
  800917:	89 e5                	mov    %esp,%ebp
  800919:	57                   	push   %edi
  80091a:	56                   	push   %esi
  80091b:	8b 45 08             	mov    0x8(%ebp),%eax
  80091e:	8b 75 0c             	mov    0xc(%ebp),%esi
  800921:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800924:	39 c6                	cmp    %eax,%esi
  800926:	73 35                	jae    80095d <memmove+0x47>
  800928:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  80092b:	39 d0                	cmp    %edx,%eax
  80092d:	73 2e                	jae    80095d <memmove+0x47>
		s += n;
		d += n;
  80092f:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800932:	89 d6                	mov    %edx,%esi
  800934:	09 fe                	or     %edi,%esi
  800936:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80093c:	75 13                	jne    800951 <memmove+0x3b>
  80093e:	f6 c1 03             	test   $0x3,%cl
  800941:	75 0e                	jne    800951 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  800943:	83 ef 04             	sub    $0x4,%edi
  800946:	8d 72 fc             	lea    -0x4(%edx),%esi
  800949:	c1 e9 02             	shr    $0x2,%ecx
  80094c:	fd                   	std    
  80094d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80094f:	eb 09                	jmp    80095a <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800951:	83 ef 01             	sub    $0x1,%edi
  800954:	8d 72 ff             	lea    -0x1(%edx),%esi
  800957:	fd                   	std    
  800958:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  80095a:	fc                   	cld    
  80095b:	eb 1d                	jmp    80097a <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095d:	89 f2                	mov    %esi,%edx
  80095f:	09 c2                	or     %eax,%edx
  800961:	f6 c2 03             	test   $0x3,%dl
  800964:	75 0f                	jne    800975 <memmove+0x5f>
  800966:	f6 c1 03             	test   $0x3,%cl
  800969:	75 0a                	jne    800975 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  80096b:	c1 e9 02             	shr    $0x2,%ecx
  80096e:	89 c7                	mov    %eax,%edi
  800970:	fc                   	cld    
  800971:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800973:	eb 05                	jmp    80097a <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800975:	89 c7                	mov    %eax,%edi
  800977:	fc                   	cld    
  800978:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  80097a:	5e                   	pop    %esi
  80097b:	5f                   	pop    %edi
  80097c:	5d                   	pop    %ebp
  80097d:	c3                   	ret    

0080097e <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80097e:	55                   	push   %ebp
  80097f:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  800981:	ff 75 10             	pushl  0x10(%ebp)
  800984:	ff 75 0c             	pushl  0xc(%ebp)
  800987:	ff 75 08             	pushl  0x8(%ebp)
  80098a:	e8 87 ff ff ff       	call   800916 <memmove>
}
  80098f:	c9                   	leave  
  800990:	c3                   	ret    

00800991 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800991:	55                   	push   %ebp
  800992:	89 e5                	mov    %esp,%ebp
  800994:	56                   	push   %esi
  800995:	53                   	push   %ebx
  800996:	8b 45 08             	mov    0x8(%ebp),%eax
  800999:	8b 55 0c             	mov    0xc(%ebp),%edx
  80099c:	89 c6                	mov    %eax,%esi
  80099e:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009a1:	eb 1a                	jmp    8009bd <memcmp+0x2c>
		if (*s1 != *s2)
  8009a3:	0f b6 08             	movzbl (%eax),%ecx
  8009a6:	0f b6 1a             	movzbl (%edx),%ebx
  8009a9:	38 d9                	cmp    %bl,%cl
  8009ab:	74 0a                	je     8009b7 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009ad:	0f b6 c1             	movzbl %cl,%eax
  8009b0:	0f b6 db             	movzbl %bl,%ebx
  8009b3:	29 d8                	sub    %ebx,%eax
  8009b5:	eb 0f                	jmp    8009c6 <memcmp+0x35>
		s1++, s2++;
  8009b7:	83 c0 01             	add    $0x1,%eax
  8009ba:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009bd:	39 f0                	cmp    %esi,%eax
  8009bf:	75 e2                	jne    8009a3 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009c1:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009c6:	5b                   	pop    %ebx
  8009c7:	5e                   	pop    %esi
  8009c8:	5d                   	pop    %ebp
  8009c9:	c3                   	ret    

008009ca <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009ca:	55                   	push   %ebp
  8009cb:	89 e5                	mov    %esp,%ebp
  8009cd:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009d3:	89 c2                	mov    %eax,%edx
  8009d5:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009d8:	eb 07                	jmp    8009e1 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009da:	38 08                	cmp    %cl,(%eax)
  8009dc:	74 07                	je     8009e5 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009de:	83 c0 01             	add    $0x1,%eax
  8009e1:	39 d0                	cmp    %edx,%eax
  8009e3:	72 f5                	jb     8009da <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009e5:	5d                   	pop    %ebp
  8009e6:	c3                   	ret    

008009e7 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009e7:	55                   	push   %ebp
  8009e8:	89 e5                	mov    %esp,%ebp
  8009ea:	57                   	push   %edi
  8009eb:	56                   	push   %esi
  8009ec:	53                   	push   %ebx
  8009ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009f0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f3:	eb 03                	jmp    8009f8 <strtol+0x11>
		s++;
  8009f5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009f8:	0f b6 01             	movzbl (%ecx),%eax
  8009fb:	3c 20                	cmp    $0x20,%al
  8009fd:	74 f6                	je     8009f5 <strtol+0xe>
  8009ff:	3c 09                	cmp    $0x9,%al
  800a01:	74 f2                	je     8009f5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a03:	3c 2b                	cmp    $0x2b,%al
  800a05:	75 0a                	jne    800a11 <strtol+0x2a>
		s++;
  800a07:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a0a:	bf 00 00 00 00       	mov    $0x0,%edi
  800a0f:	eb 11                	jmp    800a22 <strtol+0x3b>
  800a11:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a16:	3c 2d                	cmp    $0x2d,%al
  800a18:	75 08                	jne    800a22 <strtol+0x3b>
		s++, neg = 1;
  800a1a:	83 c1 01             	add    $0x1,%ecx
  800a1d:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a22:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800a28:	75 15                	jne    800a3f <strtol+0x58>
  800a2a:	80 39 30             	cmpb   $0x30,(%ecx)
  800a2d:	75 10                	jne    800a3f <strtol+0x58>
  800a2f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800a33:	75 7c                	jne    800ab1 <strtol+0xca>
		s += 2, base = 16;
  800a35:	83 c1 02             	add    $0x2,%ecx
  800a38:	bb 10 00 00 00       	mov    $0x10,%ebx
  800a3d:	eb 16                	jmp    800a55 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  800a3f:	85 db                	test   %ebx,%ebx
  800a41:	75 12                	jne    800a55 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a43:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a48:	80 39 30             	cmpb   $0x30,(%ecx)
  800a4b:	75 08                	jne    800a55 <strtol+0x6e>
		s++, base = 8;
  800a4d:	83 c1 01             	add    $0x1,%ecx
  800a50:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800a55:	b8 00 00 00 00       	mov    $0x0,%eax
  800a5a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a5d:	0f b6 11             	movzbl (%ecx),%edx
  800a60:	8d 72 d0             	lea    -0x30(%edx),%esi
  800a63:	89 f3                	mov    %esi,%ebx
  800a65:	80 fb 09             	cmp    $0x9,%bl
  800a68:	77 08                	ja     800a72 <strtol+0x8b>
			dig = *s - '0';
  800a6a:	0f be d2             	movsbl %dl,%edx
  800a6d:	83 ea 30             	sub    $0x30,%edx
  800a70:	eb 22                	jmp    800a94 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  800a72:	8d 72 9f             	lea    -0x61(%edx),%esi
  800a75:	89 f3                	mov    %esi,%ebx
  800a77:	80 fb 19             	cmp    $0x19,%bl
  800a7a:	77 08                	ja     800a84 <strtol+0x9d>
			dig = *s - 'a' + 10;
  800a7c:	0f be d2             	movsbl %dl,%edx
  800a7f:	83 ea 57             	sub    $0x57,%edx
  800a82:	eb 10                	jmp    800a94 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  800a84:	8d 72 bf             	lea    -0x41(%edx),%esi
  800a87:	89 f3                	mov    %esi,%ebx
  800a89:	80 fb 19             	cmp    $0x19,%bl
  800a8c:	77 16                	ja     800aa4 <strtol+0xbd>
			dig = *s - 'A' + 10;
  800a8e:	0f be d2             	movsbl %dl,%edx
  800a91:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  800a94:	3b 55 10             	cmp    0x10(%ebp),%edx
  800a97:	7d 0b                	jge    800aa4 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  800a99:	83 c1 01             	add    $0x1,%ecx
  800a9c:	0f af 45 10          	imul   0x10(%ebp),%eax
  800aa0:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  800aa2:	eb b9                	jmp    800a5d <strtol+0x76>

	if (endptr)
  800aa4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800aa8:	74 0d                	je     800ab7 <strtol+0xd0>
		*endptr = (char *) s;
  800aaa:	8b 75 0c             	mov    0xc(%ebp),%esi
  800aad:	89 0e                	mov    %ecx,(%esi)
  800aaf:	eb 06                	jmp    800ab7 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ab1:	85 db                	test   %ebx,%ebx
  800ab3:	74 98                	je     800a4d <strtol+0x66>
  800ab5:	eb 9e                	jmp    800a55 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  800ab7:	89 c2                	mov    %eax,%edx
  800ab9:	f7 da                	neg    %edx
  800abb:	85 ff                	test   %edi,%edi
  800abd:	0f 45 c2             	cmovne %edx,%eax
}
  800ac0:	5b                   	pop    %ebx
  800ac1:	5e                   	pop    %esi
  800ac2:	5f                   	pop    %edi
  800ac3:	5d                   	pop    %ebp
  800ac4:	c3                   	ret    

00800ac5 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  800ac5:	55                   	push   %ebp
  800ac6:	89 e5                	mov    %esp,%ebp
  800ac8:	57                   	push   %edi
  800ac9:	56                   	push   %esi
  800aca:	53                   	push   %ebx
  800acb:	83 ec 1c             	sub    $0x1c,%esp
  800ace:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800ad1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800ad4:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ad6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800ad9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800adc:	8b 7d 10             	mov    0x10(%ebp),%edi
  800adf:	8b 75 14             	mov    0x14(%ebp),%esi
  800ae2:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800ae4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800ae8:	74 1d                	je     800b07 <syscall+0x42>
  800aea:	85 c0                	test   %eax,%eax
  800aec:	7e 19                	jle    800b07 <syscall+0x42>
  800aee:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800af1:	83 ec 0c             	sub    $0xc,%esp
  800af4:	50                   	push   %eax
  800af5:	52                   	push   %edx
  800af6:	68 a4 12 80 00       	push   $0x8012a4
  800afb:	6a 23                	push   $0x23
  800afd:	68 c1 12 80 00       	push   $0x8012c1
  800b02:	e8 31 f6 ff ff       	call   800138 <_panic>

	return ret;
}
  800b07:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800b0a:	5b                   	pop    %ebx
  800b0b:	5e                   	pop    %esi
  800b0c:	5f                   	pop    %edi
  800b0d:	5d                   	pop    %ebp
  800b0e:	c3                   	ret    

00800b0f <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800b0f:	55                   	push   %ebp
  800b10:	89 e5                	mov    %esp,%ebp
  800b12:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800b15:	6a 00                	push   $0x0
  800b17:	6a 00                	push   $0x0
  800b19:	6a 00                	push   $0x0
  800b1b:	ff 75 0c             	pushl  0xc(%ebp)
  800b1e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b21:	ba 00 00 00 00       	mov    $0x0,%edx
  800b26:	b8 00 00 00 00       	mov    $0x0,%eax
  800b2b:	e8 95 ff ff ff       	call   800ac5 <syscall>
}
  800b30:	83 c4 10             	add    $0x10,%esp
  800b33:	c9                   	leave  
  800b34:	c3                   	ret    

00800b35 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b35:	55                   	push   %ebp
  800b36:	89 e5                	mov    %esp,%ebp
  800b38:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800b3b:	6a 00                	push   $0x0
  800b3d:	6a 00                	push   $0x0
  800b3f:	6a 00                	push   $0x0
  800b41:	6a 00                	push   $0x0
  800b43:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b48:	ba 00 00 00 00       	mov    $0x0,%edx
  800b4d:	b8 01 00 00 00       	mov    $0x1,%eax
  800b52:	e8 6e ff ff ff       	call   800ac5 <syscall>
}
  800b57:	c9                   	leave  
  800b58:	c3                   	ret    

00800b59 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b59:	55                   	push   %ebp
  800b5a:	89 e5                	mov    %esp,%ebp
  800b5c:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800b5f:	6a 00                	push   $0x0
  800b61:	6a 00                	push   $0x0
  800b63:	6a 00                	push   $0x0
  800b65:	6a 00                	push   $0x0
  800b67:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b6a:	ba 01 00 00 00       	mov    $0x1,%edx
  800b6f:	b8 03 00 00 00       	mov    $0x3,%eax
  800b74:	e8 4c ff ff ff       	call   800ac5 <syscall>
}
  800b79:	c9                   	leave  
  800b7a:	c3                   	ret    

00800b7b <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b7b:	55                   	push   %ebp
  800b7c:	89 e5                	mov    %esp,%ebp
  800b7e:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800b81:	6a 00                	push   $0x0
  800b83:	6a 00                	push   $0x0
  800b85:	6a 00                	push   $0x0
  800b87:	6a 00                	push   $0x0
  800b89:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b8e:	ba 00 00 00 00       	mov    $0x0,%edx
  800b93:	b8 02 00 00 00       	mov    $0x2,%eax
  800b98:	e8 28 ff ff ff       	call   800ac5 <syscall>
}
  800b9d:	c9                   	leave  
  800b9e:	c3                   	ret    

00800b9f <sys_yield>:

void
sys_yield(void)
{
  800b9f:	55                   	push   %ebp
  800ba0:	89 e5                	mov    %esp,%ebp
  800ba2:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
  800ba5:	6a 00                	push   $0x0
  800ba7:	6a 00                	push   $0x0
  800ba9:	6a 00                	push   $0x0
  800bab:	6a 00                	push   $0x0
  800bad:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bb2:	ba 00 00 00 00       	mov    $0x0,%edx
  800bb7:	b8 0a 00 00 00       	mov    $0xa,%eax
  800bbc:	e8 04 ff ff ff       	call   800ac5 <syscall>
}
  800bc1:	83 c4 10             	add    $0x10,%esp
  800bc4:	c9                   	leave  
  800bc5:	c3                   	ret    

00800bc6 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800bc6:	55                   	push   %ebp
  800bc7:	89 e5                	mov    %esp,%ebp
  800bc9:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
  800bcc:	6a 00                	push   $0x0
  800bce:	6a 00                	push   $0x0
  800bd0:	ff 75 10             	pushl  0x10(%ebp)
  800bd3:	ff 75 0c             	pushl  0xc(%ebp)
  800bd6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bd9:	ba 01 00 00 00       	mov    $0x1,%edx
  800bde:	b8 04 00 00 00       	mov    $0x4,%eax
  800be3:	e8 dd fe ff ff       	call   800ac5 <syscall>
}
  800be8:	c9                   	leave  
  800be9:	c3                   	ret    

00800bea <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800bea:	55                   	push   %ebp
  800beb:	89 e5                	mov    %esp,%ebp
  800bed:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
  800bf0:	ff 75 18             	pushl  0x18(%ebp)
  800bf3:	ff 75 14             	pushl  0x14(%ebp)
  800bf6:	ff 75 10             	pushl  0x10(%ebp)
  800bf9:	ff 75 0c             	pushl  0xc(%ebp)
  800bfc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800bff:	ba 01 00 00 00       	mov    $0x1,%edx
  800c04:	b8 05 00 00 00       	mov    $0x5,%eax
  800c09:	e8 b7 fe ff ff       	call   800ac5 <syscall>
}
  800c0e:	c9                   	leave  
  800c0f:	c3                   	ret    

00800c10 <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c10:	55                   	push   %ebp
  800c11:	89 e5                	mov    %esp,%ebp
  800c13:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
  800c16:	6a 00                	push   $0x0
  800c18:	6a 00                	push   $0x0
  800c1a:	6a 00                	push   $0x0
  800c1c:	ff 75 0c             	pushl  0xc(%ebp)
  800c1f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c22:	ba 01 00 00 00       	mov    $0x1,%edx
  800c27:	b8 06 00 00 00       	mov    $0x6,%eax
  800c2c:	e8 94 fe ff ff       	call   800ac5 <syscall>
}
  800c31:	c9                   	leave  
  800c32:	c3                   	ret    

00800c33 <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c33:	55                   	push   %ebp
  800c34:	89 e5                	mov    %esp,%ebp
  800c36:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
  800c39:	6a 00                	push   $0x0
  800c3b:	6a 00                	push   $0x0
  800c3d:	6a 00                	push   $0x0
  800c3f:	ff 75 0c             	pushl  0xc(%ebp)
  800c42:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c45:	ba 01 00 00 00       	mov    $0x1,%edx
  800c4a:	b8 08 00 00 00       	mov    $0x8,%eax
  800c4f:	e8 71 fe ff ff       	call   800ac5 <syscall>
}
  800c54:	c9                   	leave  
  800c55:	c3                   	ret    

00800c56 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800c56:	55                   	push   %ebp
  800c57:	89 e5                	mov    %esp,%ebp
  800c59:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
  800c5c:	6a 00                	push   $0x0
  800c5e:	6a 00                	push   $0x0
  800c60:	6a 00                	push   $0x0
  800c62:	ff 75 0c             	pushl  0xc(%ebp)
  800c65:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c68:	ba 01 00 00 00       	mov    $0x1,%edx
  800c6d:	b8 09 00 00 00       	mov    $0x9,%eax
  800c72:	e8 4e fe ff ff       	call   800ac5 <syscall>
}
  800c77:	c9                   	leave  
  800c78:	c3                   	ret    

00800c79 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800c79:	55                   	push   %ebp
  800c7a:	89 e5                	mov    %esp,%ebp
  800c7c:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
  800c7f:	6a 00                	push   $0x0
  800c81:	ff 75 14             	pushl  0x14(%ebp)
  800c84:	ff 75 10             	pushl  0x10(%ebp)
  800c87:	ff 75 0c             	pushl  0xc(%ebp)
  800c8a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800c8d:	ba 00 00 00 00       	mov    $0x0,%edx
  800c92:	b8 0b 00 00 00       	mov    $0xb,%eax
  800c97:	e8 29 fe ff ff       	call   800ac5 <syscall>
}
  800c9c:	c9                   	leave  
  800c9d:	c3                   	ret    

00800c9e <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800c9e:	55                   	push   %ebp
  800c9f:	89 e5                	mov    %esp,%ebp
  800ca1:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
  800ca4:	6a 00                	push   $0x0
  800ca6:	6a 00                	push   $0x0
  800ca8:	6a 00                	push   $0x0
  800caa:	6a 00                	push   $0x0
  800cac:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800caf:	ba 01 00 00 00       	mov    $0x1,%edx
  800cb4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800cb9:	e8 07 fe ff ff       	call   800ac5 <syscall>
}
  800cbe:	c9                   	leave  
  800cbf:	c3                   	ret    

00800cc0 <__udivdi3>:
  800cc0:	55                   	push   %ebp
  800cc1:	57                   	push   %edi
  800cc2:	56                   	push   %esi
  800cc3:	53                   	push   %ebx
  800cc4:	83 ec 1c             	sub    $0x1c,%esp
  800cc7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800ccb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800ccf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800cd3:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800cd7:	85 f6                	test   %esi,%esi
  800cd9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800cdd:	89 ca                	mov    %ecx,%edx
  800cdf:	89 f8                	mov    %edi,%eax
  800ce1:	75 3d                	jne    800d20 <__udivdi3+0x60>
  800ce3:	39 cf                	cmp    %ecx,%edi
  800ce5:	0f 87 c5 00 00 00    	ja     800db0 <__udivdi3+0xf0>
  800ceb:	85 ff                	test   %edi,%edi
  800ced:	89 fd                	mov    %edi,%ebp
  800cef:	75 0b                	jne    800cfc <__udivdi3+0x3c>
  800cf1:	b8 01 00 00 00       	mov    $0x1,%eax
  800cf6:	31 d2                	xor    %edx,%edx
  800cf8:	f7 f7                	div    %edi
  800cfa:	89 c5                	mov    %eax,%ebp
  800cfc:	89 c8                	mov    %ecx,%eax
  800cfe:	31 d2                	xor    %edx,%edx
  800d00:	f7 f5                	div    %ebp
  800d02:	89 c1                	mov    %eax,%ecx
  800d04:	89 d8                	mov    %ebx,%eax
  800d06:	89 cf                	mov    %ecx,%edi
  800d08:	f7 f5                	div    %ebp
  800d0a:	89 c3                	mov    %eax,%ebx
  800d0c:	89 d8                	mov    %ebx,%eax
  800d0e:	89 fa                	mov    %edi,%edx
  800d10:	83 c4 1c             	add    $0x1c,%esp
  800d13:	5b                   	pop    %ebx
  800d14:	5e                   	pop    %esi
  800d15:	5f                   	pop    %edi
  800d16:	5d                   	pop    %ebp
  800d17:	c3                   	ret    
  800d18:	90                   	nop
  800d19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800d20:	39 ce                	cmp    %ecx,%esi
  800d22:	77 74                	ja     800d98 <__udivdi3+0xd8>
  800d24:	0f bd fe             	bsr    %esi,%edi
  800d27:	83 f7 1f             	xor    $0x1f,%edi
  800d2a:	0f 84 98 00 00 00    	je     800dc8 <__udivdi3+0x108>
  800d30:	bb 20 00 00 00       	mov    $0x20,%ebx
  800d35:	89 f9                	mov    %edi,%ecx
  800d37:	89 c5                	mov    %eax,%ebp
  800d39:	29 fb                	sub    %edi,%ebx
  800d3b:	d3 e6                	shl    %cl,%esi
  800d3d:	89 d9                	mov    %ebx,%ecx
  800d3f:	d3 ed                	shr    %cl,%ebp
  800d41:	89 f9                	mov    %edi,%ecx
  800d43:	d3 e0                	shl    %cl,%eax
  800d45:	09 ee                	or     %ebp,%esi
  800d47:	89 d9                	mov    %ebx,%ecx
  800d49:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800d4d:	89 d5                	mov    %edx,%ebp
  800d4f:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d53:	d3 ed                	shr    %cl,%ebp
  800d55:	89 f9                	mov    %edi,%ecx
  800d57:	d3 e2                	shl    %cl,%edx
  800d59:	89 d9                	mov    %ebx,%ecx
  800d5b:	d3 e8                	shr    %cl,%eax
  800d5d:	09 c2                	or     %eax,%edx
  800d5f:	89 d0                	mov    %edx,%eax
  800d61:	89 ea                	mov    %ebp,%edx
  800d63:	f7 f6                	div    %esi
  800d65:	89 d5                	mov    %edx,%ebp
  800d67:	89 c3                	mov    %eax,%ebx
  800d69:	f7 64 24 0c          	mull   0xc(%esp)
  800d6d:	39 d5                	cmp    %edx,%ebp
  800d6f:	72 10                	jb     800d81 <__udivdi3+0xc1>
  800d71:	8b 74 24 08          	mov    0x8(%esp),%esi
  800d75:	89 f9                	mov    %edi,%ecx
  800d77:	d3 e6                	shl    %cl,%esi
  800d79:	39 c6                	cmp    %eax,%esi
  800d7b:	73 07                	jae    800d84 <__udivdi3+0xc4>
  800d7d:	39 d5                	cmp    %edx,%ebp
  800d7f:	75 03                	jne    800d84 <__udivdi3+0xc4>
  800d81:	83 eb 01             	sub    $0x1,%ebx
  800d84:	31 ff                	xor    %edi,%edi
  800d86:	89 d8                	mov    %ebx,%eax
  800d88:	89 fa                	mov    %edi,%edx
  800d8a:	83 c4 1c             	add    $0x1c,%esp
  800d8d:	5b                   	pop    %ebx
  800d8e:	5e                   	pop    %esi
  800d8f:	5f                   	pop    %edi
  800d90:	5d                   	pop    %ebp
  800d91:	c3                   	ret    
  800d92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800d98:	31 ff                	xor    %edi,%edi
  800d9a:	31 db                	xor    %ebx,%ebx
  800d9c:	89 d8                	mov    %ebx,%eax
  800d9e:	89 fa                	mov    %edi,%edx
  800da0:	83 c4 1c             	add    $0x1c,%esp
  800da3:	5b                   	pop    %ebx
  800da4:	5e                   	pop    %esi
  800da5:	5f                   	pop    %edi
  800da6:	5d                   	pop    %ebp
  800da7:	c3                   	ret    
  800da8:	90                   	nop
  800da9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800db0:	89 d8                	mov    %ebx,%eax
  800db2:	f7 f7                	div    %edi
  800db4:	31 ff                	xor    %edi,%edi
  800db6:	89 c3                	mov    %eax,%ebx
  800db8:	89 d8                	mov    %ebx,%eax
  800dba:	89 fa                	mov    %edi,%edx
  800dbc:	83 c4 1c             	add    $0x1c,%esp
  800dbf:	5b                   	pop    %ebx
  800dc0:	5e                   	pop    %esi
  800dc1:	5f                   	pop    %edi
  800dc2:	5d                   	pop    %ebp
  800dc3:	c3                   	ret    
  800dc4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dc8:	39 ce                	cmp    %ecx,%esi
  800dca:	72 0c                	jb     800dd8 <__udivdi3+0x118>
  800dcc:	31 db                	xor    %ebx,%ebx
  800dce:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800dd2:	0f 87 34 ff ff ff    	ja     800d0c <__udivdi3+0x4c>
  800dd8:	bb 01 00 00 00       	mov    $0x1,%ebx
  800ddd:	e9 2a ff ff ff       	jmp    800d0c <__udivdi3+0x4c>
  800de2:	66 90                	xchg   %ax,%ax
  800de4:	66 90                	xchg   %ax,%ax
  800de6:	66 90                	xchg   %ax,%ax
  800de8:	66 90                	xchg   %ax,%ax
  800dea:	66 90                	xchg   %ax,%ax
  800dec:	66 90                	xchg   %ax,%ax
  800dee:	66 90                	xchg   %ax,%ax

00800df0 <__umoddi3>:
  800df0:	55                   	push   %ebp
  800df1:	57                   	push   %edi
  800df2:	56                   	push   %esi
  800df3:	53                   	push   %ebx
  800df4:	83 ec 1c             	sub    $0x1c,%esp
  800df7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800dfb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800dff:	8b 74 24 34          	mov    0x34(%esp),%esi
  800e03:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800e07:	85 d2                	test   %edx,%edx
  800e09:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800e0d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800e11:	89 f3                	mov    %esi,%ebx
  800e13:	89 3c 24             	mov    %edi,(%esp)
  800e16:	89 74 24 04          	mov    %esi,0x4(%esp)
  800e1a:	75 1c                	jne    800e38 <__umoddi3+0x48>
  800e1c:	39 f7                	cmp    %esi,%edi
  800e1e:	76 50                	jbe    800e70 <__umoddi3+0x80>
  800e20:	89 c8                	mov    %ecx,%eax
  800e22:	89 f2                	mov    %esi,%edx
  800e24:	f7 f7                	div    %edi
  800e26:	89 d0                	mov    %edx,%eax
  800e28:	31 d2                	xor    %edx,%edx
  800e2a:	83 c4 1c             	add    $0x1c,%esp
  800e2d:	5b                   	pop    %ebx
  800e2e:	5e                   	pop    %esi
  800e2f:	5f                   	pop    %edi
  800e30:	5d                   	pop    %ebp
  800e31:	c3                   	ret    
  800e32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800e38:	39 f2                	cmp    %esi,%edx
  800e3a:	89 d0                	mov    %edx,%eax
  800e3c:	77 52                	ja     800e90 <__umoddi3+0xa0>
  800e3e:	0f bd ea             	bsr    %edx,%ebp
  800e41:	83 f5 1f             	xor    $0x1f,%ebp
  800e44:	75 5a                	jne    800ea0 <__umoddi3+0xb0>
  800e46:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800e4a:	0f 82 e0 00 00 00    	jb     800f30 <__umoddi3+0x140>
  800e50:	39 0c 24             	cmp    %ecx,(%esp)
  800e53:	0f 86 d7 00 00 00    	jbe    800f30 <__umoddi3+0x140>
  800e59:	8b 44 24 08          	mov    0x8(%esp),%eax
  800e5d:	8b 54 24 04          	mov    0x4(%esp),%edx
  800e61:	83 c4 1c             	add    $0x1c,%esp
  800e64:	5b                   	pop    %ebx
  800e65:	5e                   	pop    %esi
  800e66:	5f                   	pop    %edi
  800e67:	5d                   	pop    %ebp
  800e68:	c3                   	ret    
  800e69:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e70:	85 ff                	test   %edi,%edi
  800e72:	89 fd                	mov    %edi,%ebp
  800e74:	75 0b                	jne    800e81 <__umoddi3+0x91>
  800e76:	b8 01 00 00 00       	mov    $0x1,%eax
  800e7b:	31 d2                	xor    %edx,%edx
  800e7d:	f7 f7                	div    %edi
  800e7f:	89 c5                	mov    %eax,%ebp
  800e81:	89 f0                	mov    %esi,%eax
  800e83:	31 d2                	xor    %edx,%edx
  800e85:	f7 f5                	div    %ebp
  800e87:	89 c8                	mov    %ecx,%eax
  800e89:	f7 f5                	div    %ebp
  800e8b:	89 d0                	mov    %edx,%eax
  800e8d:	eb 99                	jmp    800e28 <__umoddi3+0x38>
  800e8f:	90                   	nop
  800e90:	89 c8                	mov    %ecx,%eax
  800e92:	89 f2                	mov    %esi,%edx
  800e94:	83 c4 1c             	add    $0x1c,%esp
  800e97:	5b                   	pop    %ebx
  800e98:	5e                   	pop    %esi
  800e99:	5f                   	pop    %edi
  800e9a:	5d                   	pop    %ebp
  800e9b:	c3                   	ret    
  800e9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ea0:	8b 34 24             	mov    (%esp),%esi
  800ea3:	bf 20 00 00 00       	mov    $0x20,%edi
  800ea8:	89 e9                	mov    %ebp,%ecx
  800eaa:	29 ef                	sub    %ebp,%edi
  800eac:	d3 e0                	shl    %cl,%eax
  800eae:	89 f9                	mov    %edi,%ecx
  800eb0:	89 f2                	mov    %esi,%edx
  800eb2:	d3 ea                	shr    %cl,%edx
  800eb4:	89 e9                	mov    %ebp,%ecx
  800eb6:	09 c2                	or     %eax,%edx
  800eb8:	89 d8                	mov    %ebx,%eax
  800eba:	89 14 24             	mov    %edx,(%esp)
  800ebd:	89 f2                	mov    %esi,%edx
  800ebf:	d3 e2                	shl    %cl,%edx
  800ec1:	89 f9                	mov    %edi,%ecx
  800ec3:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ec7:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800ecb:	d3 e8                	shr    %cl,%eax
  800ecd:	89 e9                	mov    %ebp,%ecx
  800ecf:	89 c6                	mov    %eax,%esi
  800ed1:	d3 e3                	shl    %cl,%ebx
  800ed3:	89 f9                	mov    %edi,%ecx
  800ed5:	89 d0                	mov    %edx,%eax
  800ed7:	d3 e8                	shr    %cl,%eax
  800ed9:	89 e9                	mov    %ebp,%ecx
  800edb:	09 d8                	or     %ebx,%eax
  800edd:	89 d3                	mov    %edx,%ebx
  800edf:	89 f2                	mov    %esi,%edx
  800ee1:	f7 34 24             	divl   (%esp)
  800ee4:	89 d6                	mov    %edx,%esi
  800ee6:	d3 e3                	shl    %cl,%ebx
  800ee8:	f7 64 24 04          	mull   0x4(%esp)
  800eec:	39 d6                	cmp    %edx,%esi
  800eee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800ef2:	89 d1                	mov    %edx,%ecx
  800ef4:	89 c3                	mov    %eax,%ebx
  800ef6:	72 08                	jb     800f00 <__umoddi3+0x110>
  800ef8:	75 11                	jne    800f0b <__umoddi3+0x11b>
  800efa:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800efe:	73 0b                	jae    800f0b <__umoddi3+0x11b>
  800f00:	2b 44 24 04          	sub    0x4(%esp),%eax
  800f04:	1b 14 24             	sbb    (%esp),%edx
  800f07:	89 d1                	mov    %edx,%ecx
  800f09:	89 c3                	mov    %eax,%ebx
  800f0b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800f0f:	29 da                	sub    %ebx,%edx
  800f11:	19 ce                	sbb    %ecx,%esi
  800f13:	89 f9                	mov    %edi,%ecx
  800f15:	89 f0                	mov    %esi,%eax
  800f17:	d3 e0                	shl    %cl,%eax
  800f19:	89 e9                	mov    %ebp,%ecx
  800f1b:	d3 ea                	shr    %cl,%edx
  800f1d:	89 e9                	mov    %ebp,%ecx
  800f1f:	d3 ee                	shr    %cl,%esi
  800f21:	09 d0                	or     %edx,%eax
  800f23:	89 f2                	mov    %esi,%edx
  800f25:	83 c4 1c             	add    $0x1c,%esp
  800f28:	5b                   	pop    %ebx
  800f29:	5e                   	pop    %esi
  800f2a:	5f                   	pop    %edi
  800f2b:	5d                   	pop    %ebp
  800f2c:	c3                   	ret    
  800f2d:	8d 76 00             	lea    0x0(%esi),%esi
  800f30:	29 f9                	sub    %edi,%ecx
  800f32:	19 d6                	sbb    %edx,%esi
  800f34:	89 74 24 04          	mov    %esi,0x4(%esp)
  800f38:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f3c:	e9 18 ff ff ff       	jmp    800e59 <__umoddi3+0x69>
