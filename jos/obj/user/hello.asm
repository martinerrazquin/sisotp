
obj/user/hello:     file format elf32-i386


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
  80002c:	e8 2d 00 00 00       	call   80005e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 14             	sub    $0x14,%esp
	cprintf("hello, world\n");
  800039:	68 a4 0d 80 00       	push   $0x800da4
  80003e:	e8 f6 00 00 00       	call   800139 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800043:	a1 04 20 80 00       	mov    0x802004,%eax
  800048:	8b 40 48             	mov    0x48(%eax),%eax
  80004b:	83 c4 08             	add    $0x8,%esp
  80004e:	50                   	push   %eax
  80004f:	68 b2 0d 80 00       	push   $0x800db2
  800054:	e8 e0 00 00 00       	call   800139 <cprintf>
}
  800059:	83 c4 10             	add    $0x10,%esp
  80005c:	c9                   	leave  
  80005d:	c3                   	ret    

0080005e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005e:	55                   	push   %ebp
  80005f:	89 e5                	mov    %esp,%ebp
  800061:	83 ec 08             	sub    $0x8,%esp
  800064:	8b 45 08             	mov    0x8(%ebp),%eax
  800067:	8b 55 0c             	mov    0xc(%ebp),%edx
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = 0;
  80006a:	c7 05 04 20 80 00 00 	movl   $0x0,0x802004
  800071:	00 00 00 

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800074:	85 c0                	test   %eax,%eax
  800076:	7e 08                	jle    800080 <libmain+0x22>
		binaryname = argv[0];
  800078:	8b 0a                	mov    (%edx),%ecx
  80007a:	89 0d 00 20 80 00    	mov    %ecx,0x802000

	// call user main routine
	umain(argc, argv);
  800080:	83 ec 08             	sub    $0x8,%esp
  800083:	52                   	push   %edx
  800084:	50                   	push   %eax
  800085:	e8 a9 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008a:	e8 05 00 00 00       	call   800094 <exit>
}
  80008f:	83 c4 10             	add    $0x10,%esp
  800092:	c9                   	leave  
  800093:	c3                   	ret    

00800094 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800094:	55                   	push   %ebp
  800095:	89 e5                	mov    %esp,%ebp
  800097:	83 ec 14             	sub    $0x14,%esp
	sys_env_destroy(0);
  80009a:	6a 00                	push   $0x0
  80009c:	e8 e6 09 00 00       	call   800a87 <sys_env_destroy>
}
  8000a1:	83 c4 10             	add    $0x10,%esp
  8000a4:	c9                   	leave  
  8000a5:	c3                   	ret    

008000a6 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000a6:	55                   	push   %ebp
  8000a7:	89 e5                	mov    %esp,%ebp
  8000a9:	53                   	push   %ebx
  8000aa:	83 ec 04             	sub    $0x4,%esp
  8000ad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b0:	8b 13                	mov    (%ebx),%edx
  8000b2:	8d 42 01             	lea    0x1(%edx),%eax
  8000b5:	89 03                	mov    %eax,(%ebx)
  8000b7:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000ba:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000be:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c3:	75 1a                	jne    8000df <putch+0x39>
		sys_cputs(b->buf, b->idx);
  8000c5:	83 ec 08             	sub    $0x8,%esp
  8000c8:	68 ff 00 00 00       	push   $0xff
  8000cd:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d0:	50                   	push   %eax
  8000d1:	e8 67 09 00 00       	call   800a3d <sys_cputs>
		b->idx = 0;
  8000d6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
  8000dc:	83 c4 10             	add    $0x10,%esp
	}
	b->cnt++;
  8000df:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8000e6:	c9                   	leave  
  8000e7:	c3                   	ret    

008000e8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000e8:	55                   	push   %ebp
  8000e9:	89 e5                	mov    %esp,%ebp
  8000eb:	81 ec 18 01 00 00    	sub    $0x118,%esp
	struct printbuf b;

	b.idx = 0;
  8000f1:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000f8:	00 00 00 
	b.cnt = 0;
  8000fb:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800102:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800105:	ff 75 0c             	pushl  0xc(%ebp)
  800108:	ff 75 08             	pushl  0x8(%ebp)
  80010b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800111:	50                   	push   %eax
  800112:	68 a6 00 80 00       	push   $0x8000a6
  800117:	e8 86 01 00 00       	call   8002a2 <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80011c:	83 c4 08             	add    $0x8,%esp
  80011f:	ff b5 f0 fe ff ff    	pushl  -0x110(%ebp)
  800125:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80012b:	50                   	push   %eax
  80012c:	e8 0c 09 00 00       	call   800a3d <sys_cputs>

	return b.cnt;
}
  800131:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800137:	c9                   	leave  
  800138:	c3                   	ret    

00800139 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800139:	55                   	push   %ebp
  80013a:	89 e5                	mov    %esp,%ebp
  80013c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80013f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800142:	50                   	push   %eax
  800143:	ff 75 08             	pushl  0x8(%ebp)
  800146:	e8 9d ff ff ff       	call   8000e8 <vcprintf>
	va_end(ap);

	return cnt;
}
  80014b:	c9                   	leave  
  80014c:	c3                   	ret    

0080014d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  80014d:	55                   	push   %ebp
  80014e:	89 e5                	mov    %esp,%ebp
  800150:	57                   	push   %edi
  800151:	56                   	push   %esi
  800152:	53                   	push   %ebx
  800153:	83 ec 1c             	sub    $0x1c,%esp
  800156:	89 c7                	mov    %eax,%edi
  800158:	89 d6                	mov    %edx,%esi
  80015a:	8b 45 08             	mov    0x8(%ebp),%eax
  80015d:	8b 55 0c             	mov    0xc(%ebp),%edx
  800160:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800163:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800166:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800169:	bb 00 00 00 00       	mov    $0x0,%ebx
  80016e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  800171:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
  800174:	39 d3                	cmp    %edx,%ebx
  800176:	72 05                	jb     80017d <printnum+0x30>
  800178:	39 45 10             	cmp    %eax,0x10(%ebp)
  80017b:	77 45                	ja     8001c2 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  80017d:	83 ec 0c             	sub    $0xc,%esp
  800180:	ff 75 18             	pushl  0x18(%ebp)
  800183:	8b 45 14             	mov    0x14(%ebp),%eax
  800186:	8d 58 ff             	lea    -0x1(%eax),%ebx
  800189:	53                   	push   %ebx
  80018a:	ff 75 10             	pushl  0x10(%ebp)
  80018d:	83 ec 08             	sub    $0x8,%esp
  800190:	ff 75 e4             	pushl  -0x1c(%ebp)
  800193:	ff 75 e0             	pushl  -0x20(%ebp)
  800196:	ff 75 dc             	pushl  -0x24(%ebp)
  800199:	ff 75 d8             	pushl  -0x28(%ebp)
  80019c:	e8 7f 09 00 00       	call   800b20 <__udivdi3>
  8001a1:	83 c4 18             	add    $0x18,%esp
  8001a4:	52                   	push   %edx
  8001a5:	50                   	push   %eax
  8001a6:	89 f2                	mov    %esi,%edx
  8001a8:	89 f8                	mov    %edi,%eax
  8001aa:	e8 9e ff ff ff       	call   80014d <printnum>
  8001af:	83 c4 20             	add    $0x20,%esp
  8001b2:	eb 18                	jmp    8001cc <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8001b4:	83 ec 08             	sub    $0x8,%esp
  8001b7:	56                   	push   %esi
  8001b8:	ff 75 18             	pushl  0x18(%ebp)
  8001bb:	ff d7                	call   *%edi
  8001bd:	83 c4 10             	add    $0x10,%esp
  8001c0:	eb 03                	jmp    8001c5 <printnum+0x78>
  8001c2:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8001c5:	83 eb 01             	sub    $0x1,%ebx
  8001c8:	85 db                	test   %ebx,%ebx
  8001ca:	7f e8                	jg     8001b4 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8001cc:	83 ec 08             	sub    $0x8,%esp
  8001cf:	56                   	push   %esi
  8001d0:	83 ec 04             	sub    $0x4,%esp
  8001d3:	ff 75 e4             	pushl  -0x1c(%ebp)
  8001d6:	ff 75 e0             	pushl  -0x20(%ebp)
  8001d9:	ff 75 dc             	pushl  -0x24(%ebp)
  8001dc:	ff 75 d8             	pushl  -0x28(%ebp)
  8001df:	e8 6c 0a 00 00       	call   800c50 <__umoddi3>
  8001e4:	83 c4 14             	add    $0x14,%esp
  8001e7:	0f be 80 d3 0d 80 00 	movsbl 0x800dd3(%eax),%eax
  8001ee:	50                   	push   %eax
  8001ef:	ff d7                	call   *%edi
}
  8001f1:	83 c4 10             	add    $0x10,%esp
  8001f4:	8d 65 f4             	lea    -0xc(%ebp),%esp
  8001f7:	5b                   	pop    %ebx
  8001f8:	5e                   	pop    %esi
  8001f9:	5f                   	pop    %edi
  8001fa:	5d                   	pop    %ebp
  8001fb:	c3                   	ret    

008001fc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8001fc:	55                   	push   %ebp
  8001fd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8001ff:	83 fa 01             	cmp    $0x1,%edx
  800202:	7e 0e                	jle    800212 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800204:	8b 10                	mov    (%eax),%edx
  800206:	8d 4a 08             	lea    0x8(%edx),%ecx
  800209:	89 08                	mov    %ecx,(%eax)
  80020b:	8b 02                	mov    (%edx),%eax
  80020d:	8b 52 04             	mov    0x4(%edx),%edx
  800210:	eb 22                	jmp    800234 <getuint+0x38>
	else if (lflag)
  800212:	85 d2                	test   %edx,%edx
  800214:	74 10                	je     800226 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800216:	8b 10                	mov    (%eax),%edx
  800218:	8d 4a 04             	lea    0x4(%edx),%ecx
  80021b:	89 08                	mov    %ecx,(%eax)
  80021d:	8b 02                	mov    (%edx),%eax
  80021f:	ba 00 00 00 00       	mov    $0x0,%edx
  800224:	eb 0e                	jmp    800234 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800226:	8b 10                	mov    (%eax),%edx
  800228:	8d 4a 04             	lea    0x4(%edx),%ecx
  80022b:	89 08                	mov    %ecx,(%eax)
  80022d:	8b 02                	mov    (%edx),%eax
  80022f:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800234:	5d                   	pop    %ebp
  800235:	c3                   	ret    

00800236 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
  800236:	55                   	push   %ebp
  800237:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800239:	83 fa 01             	cmp    $0x1,%edx
  80023c:	7e 0e                	jle    80024c <getint+0x16>
		return va_arg(*ap, long long);
  80023e:	8b 10                	mov    (%eax),%edx
  800240:	8d 4a 08             	lea    0x8(%edx),%ecx
  800243:	89 08                	mov    %ecx,(%eax)
  800245:	8b 02                	mov    (%edx),%eax
  800247:	8b 52 04             	mov    0x4(%edx),%edx
  80024a:	eb 1a                	jmp    800266 <getint+0x30>
	else if (lflag)
  80024c:	85 d2                	test   %edx,%edx
  80024e:	74 0c                	je     80025c <getint+0x26>
		return va_arg(*ap, long);
  800250:	8b 10                	mov    (%eax),%edx
  800252:	8d 4a 04             	lea    0x4(%edx),%ecx
  800255:	89 08                	mov    %ecx,(%eax)
  800257:	8b 02                	mov    (%edx),%eax
  800259:	99                   	cltd   
  80025a:	eb 0a                	jmp    800266 <getint+0x30>
	else
		return va_arg(*ap, int);
  80025c:	8b 10                	mov    (%eax),%edx
  80025e:	8d 4a 04             	lea    0x4(%edx),%ecx
  800261:	89 08                	mov    %ecx,(%eax)
  800263:	8b 02                	mov    (%edx),%eax
  800265:	99                   	cltd   
}
  800266:	5d                   	pop    %ebp
  800267:	c3                   	ret    

00800268 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800268:	55                   	push   %ebp
  800269:	89 e5                	mov    %esp,%ebp
  80026b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80026e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800272:	8b 10                	mov    (%eax),%edx
  800274:	3b 50 04             	cmp    0x4(%eax),%edx
  800277:	73 0a                	jae    800283 <sprintputch+0x1b>
		*b->buf++ = ch;
  800279:	8d 4a 01             	lea    0x1(%edx),%ecx
  80027c:	89 08                	mov    %ecx,(%eax)
  80027e:	8b 45 08             	mov    0x8(%ebp),%eax
  800281:	88 02                	mov    %al,(%edx)
}
  800283:	5d                   	pop    %ebp
  800284:	c3                   	ret    

00800285 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800285:	55                   	push   %ebp
  800286:	89 e5                	mov    %esp,%ebp
  800288:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
  80028b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80028e:	50                   	push   %eax
  80028f:	ff 75 10             	pushl  0x10(%ebp)
  800292:	ff 75 0c             	pushl  0xc(%ebp)
  800295:	ff 75 08             	pushl  0x8(%ebp)
  800298:	e8 05 00 00 00       	call   8002a2 <vprintfmt>
	va_end(ap);
}
  80029d:	83 c4 10             	add    $0x10,%esp
  8002a0:	c9                   	leave  
  8002a1:	c3                   	ret    

008002a2 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002a2:	55                   	push   %ebp
  8002a3:	89 e5                	mov    %esp,%ebp
  8002a5:	57                   	push   %edi
  8002a6:	56                   	push   %esi
  8002a7:	53                   	push   %ebx
  8002a8:	83 ec 2c             	sub    $0x2c,%esp
  8002ab:	8b 75 08             	mov    0x8(%ebp),%esi
  8002ae:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  8002b1:	8b 7d 10             	mov    0x10(%ebp),%edi
  8002b4:	eb 12                	jmp    8002c8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002b6:	85 c0                	test   %eax,%eax
  8002b8:	0f 84 44 03 00 00    	je     800602 <vprintfmt+0x360>
				return;
			putch(ch, putdat);
  8002be:	83 ec 08             	sub    $0x8,%esp
  8002c1:	53                   	push   %ebx
  8002c2:	50                   	push   %eax
  8002c3:	ff d6                	call   *%esi
  8002c5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8002c8:	83 c7 01             	add    $0x1,%edi
  8002cb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8002cf:	83 f8 25             	cmp    $0x25,%eax
  8002d2:	75 e2                	jne    8002b6 <vprintfmt+0x14>
  8002d4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
  8002d8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  8002df:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  8002e6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
  8002ed:	ba 00 00 00 00       	mov    $0x0,%edx
  8002f2:	eb 07                	jmp    8002fb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
  8002f7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8002fb:	8d 47 01             	lea    0x1(%edi),%eax
  8002fe:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800301:	0f b6 07             	movzbl (%edi),%eax
  800304:	0f b6 c8             	movzbl %al,%ecx
  800307:	83 e8 23             	sub    $0x23,%eax
  80030a:	3c 55                	cmp    $0x55,%al
  80030c:	0f 87 d5 02 00 00    	ja     8005e7 <vprintfmt+0x345>
  800312:	0f b6 c0             	movzbl %al,%eax
  800315:	ff 24 85 60 0e 80 00 	jmp    *0x800e60(,%eax,4)
  80031c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  80031f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
  800323:	eb d6                	jmp    8002fb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800325:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800328:	b8 00 00 00 00       	mov    $0x0,%eax
  80032d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800330:	8d 04 80             	lea    (%eax,%eax,4),%eax
  800333:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
  800337:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
  80033a:	8d 51 d0             	lea    -0x30(%ecx),%edx
  80033d:	83 fa 09             	cmp    $0x9,%edx
  800340:	77 39                	ja     80037b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800342:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800345:	eb e9                	jmp    800330 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800347:	8b 45 14             	mov    0x14(%ebp),%eax
  80034a:	8d 48 04             	lea    0x4(%eax),%ecx
  80034d:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800350:	8b 00                	mov    (%eax),%eax
  800352:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800355:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800358:	eb 27                	jmp    800381 <vprintfmt+0xdf>
  80035a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  80035d:	85 c0                	test   %eax,%eax
  80035f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800364:	0f 49 c8             	cmovns %eax,%ecx
  800367:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80036d:	eb 8c                	jmp    8002fb <vprintfmt+0x59>
  80036f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800372:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
  800379:	eb 80                	jmp    8002fb <vprintfmt+0x59>
  80037b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  80037e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
  800381:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800385:	0f 89 70 ff ff ff    	jns    8002fb <vprintfmt+0x59>
				width = precision, precision = -1;
  80038b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  80038e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800391:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800398:	e9 5e ff ff ff       	jmp    8002fb <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  80039d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003a0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003a3:	e9 53 ff ff ff       	jmp    8002fb <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003a8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ab:	8d 50 04             	lea    0x4(%eax),%edx
  8003ae:	89 55 14             	mov    %edx,0x14(%ebp)
  8003b1:	83 ec 08             	sub    $0x8,%esp
  8003b4:	53                   	push   %ebx
  8003b5:	ff 30                	pushl  (%eax)
  8003b7:	ff d6                	call   *%esi
			break;
  8003b9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
  8003bf:	e9 04 ff ff ff       	jmp    8002c8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003c4:	8b 45 14             	mov    0x14(%ebp),%eax
  8003c7:	8d 50 04             	lea    0x4(%eax),%edx
  8003ca:	89 55 14             	mov    %edx,0x14(%ebp)
  8003cd:	8b 00                	mov    (%eax),%eax
  8003cf:	99                   	cltd   
  8003d0:	31 d0                	xor    %edx,%eax
  8003d2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003d4:	83 f8 06             	cmp    $0x6,%eax
  8003d7:	7f 0b                	jg     8003e4 <vprintfmt+0x142>
  8003d9:	8b 14 85 b8 0f 80 00 	mov    0x800fb8(,%eax,4),%edx
  8003e0:	85 d2                	test   %edx,%edx
  8003e2:	75 18                	jne    8003fc <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
  8003e4:	50                   	push   %eax
  8003e5:	68 eb 0d 80 00       	push   $0x800deb
  8003ea:	53                   	push   %ebx
  8003eb:	56                   	push   %esi
  8003ec:	e8 94 fe ff ff       	call   800285 <printfmt>
  8003f1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003f4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
  8003f7:	e9 cc fe ff ff       	jmp    8002c8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
  8003fc:	52                   	push   %edx
  8003fd:	68 f4 0d 80 00       	push   $0x800df4
  800402:	53                   	push   %ebx
  800403:	56                   	push   %esi
  800404:	e8 7c fe ff ff       	call   800285 <printfmt>
  800409:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  80040f:	e9 b4 fe ff ff       	jmp    8002c8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800414:	8b 45 14             	mov    0x14(%ebp),%eax
  800417:	8d 50 04             	lea    0x4(%eax),%edx
  80041a:	89 55 14             	mov    %edx,0x14(%ebp)
  80041d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
  80041f:	85 ff                	test   %edi,%edi
  800421:	b8 e4 0d 80 00       	mov    $0x800de4,%eax
  800426:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
  800429:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  80042d:	0f 8e 94 00 00 00    	jle    8004c7 <vprintfmt+0x225>
  800433:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
  800437:	0f 84 98 00 00 00    	je     8004d5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
  80043d:	83 ec 08             	sub    $0x8,%esp
  800440:	ff 75 d0             	pushl  -0x30(%ebp)
  800443:	57                   	push   %edi
  800444:	e8 41 02 00 00       	call   80068a <strnlen>
  800449:	8b 4d e0             	mov    -0x20(%ebp),%ecx
  80044c:	29 c1                	sub    %eax,%ecx
  80044e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
  800451:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
  800454:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
  800458:	89 45 e0             	mov    %eax,-0x20(%ebp)
  80045b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
  80045e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800460:	eb 0f                	jmp    800471 <vprintfmt+0x1cf>
					putch(padc, putdat);
  800462:	83 ec 08             	sub    $0x8,%esp
  800465:	53                   	push   %ebx
  800466:	ff 75 e0             	pushl  -0x20(%ebp)
  800469:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80046b:	83 ef 01             	sub    $0x1,%edi
  80046e:	83 c4 10             	add    $0x10,%esp
  800471:	85 ff                	test   %edi,%edi
  800473:	7f ed                	jg     800462 <vprintfmt+0x1c0>
  800475:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  800478:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  80047b:	85 c9                	test   %ecx,%ecx
  80047d:	b8 00 00 00 00       	mov    $0x0,%eax
  800482:	0f 49 c1             	cmovns %ecx,%eax
  800485:	29 c1                	sub    %eax,%ecx
  800487:	89 75 08             	mov    %esi,0x8(%ebp)
  80048a:	8b 75 d0             	mov    -0x30(%ebp),%esi
  80048d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  800490:	89 cb                	mov    %ecx,%ebx
  800492:	eb 4d                	jmp    8004e1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800494:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  800498:	74 1b                	je     8004b5 <vprintfmt+0x213>
  80049a:	0f be c0             	movsbl %al,%eax
  80049d:	83 e8 20             	sub    $0x20,%eax
  8004a0:	83 f8 5e             	cmp    $0x5e,%eax
  8004a3:	76 10                	jbe    8004b5 <vprintfmt+0x213>
					putch('?', putdat);
  8004a5:	83 ec 08             	sub    $0x8,%esp
  8004a8:	ff 75 0c             	pushl  0xc(%ebp)
  8004ab:	6a 3f                	push   $0x3f
  8004ad:	ff 55 08             	call   *0x8(%ebp)
  8004b0:	83 c4 10             	add    $0x10,%esp
  8004b3:	eb 0d                	jmp    8004c2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
  8004b5:	83 ec 08             	sub    $0x8,%esp
  8004b8:	ff 75 0c             	pushl  0xc(%ebp)
  8004bb:	52                   	push   %edx
  8004bc:	ff 55 08             	call   *0x8(%ebp)
  8004bf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004c2:	83 eb 01             	sub    $0x1,%ebx
  8004c5:	eb 1a                	jmp    8004e1 <vprintfmt+0x23f>
  8004c7:	89 75 08             	mov    %esi,0x8(%ebp)
  8004ca:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004cd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004d0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004d3:	eb 0c                	jmp    8004e1 <vprintfmt+0x23f>
  8004d5:	89 75 08             	mov    %esi,0x8(%ebp)
  8004d8:	8b 75 d0             	mov    -0x30(%ebp),%esi
  8004db:	89 5d 0c             	mov    %ebx,0xc(%ebp)
  8004de:	8b 5d e0             	mov    -0x20(%ebp),%ebx
  8004e1:	83 c7 01             	add    $0x1,%edi
  8004e4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
  8004e8:	0f be d0             	movsbl %al,%edx
  8004eb:	85 d2                	test   %edx,%edx
  8004ed:	74 23                	je     800512 <vprintfmt+0x270>
  8004ef:	85 f6                	test   %esi,%esi
  8004f1:	78 a1                	js     800494 <vprintfmt+0x1f2>
  8004f3:	83 ee 01             	sub    $0x1,%esi
  8004f6:	79 9c                	jns    800494 <vprintfmt+0x1f2>
  8004f8:	89 df                	mov    %ebx,%edi
  8004fa:	8b 75 08             	mov    0x8(%ebp),%esi
  8004fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800500:	eb 18                	jmp    80051a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800502:	83 ec 08             	sub    $0x8,%esp
  800505:	53                   	push   %ebx
  800506:	6a 20                	push   $0x20
  800508:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80050a:	83 ef 01             	sub    $0x1,%edi
  80050d:	83 c4 10             	add    $0x10,%esp
  800510:	eb 08                	jmp    80051a <vprintfmt+0x278>
  800512:	89 df                	mov    %ebx,%edi
  800514:	8b 75 08             	mov    0x8(%ebp),%esi
  800517:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  80051a:	85 ff                	test   %edi,%edi
  80051c:	7f e4                	jg     800502 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80051e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  800521:	e9 a2 fd ff ff       	jmp    8002c8 <vprintfmt+0x26>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  800526:	8d 45 14             	lea    0x14(%ebp),%eax
  800529:	e8 08 fd ff ff       	call   800236 <getint>
  80052e:	89 45 d8             	mov    %eax,-0x28(%ebp)
  800531:	89 55 dc             	mov    %edx,-0x24(%ebp)
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800534:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800539:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  80053d:	79 74                	jns    8005b3 <vprintfmt+0x311>
				putch('-', putdat);
  80053f:	83 ec 08             	sub    $0x8,%esp
  800542:	53                   	push   %ebx
  800543:	6a 2d                	push   $0x2d
  800545:	ff d6                	call   *%esi
				num = -(long long) num;
  800547:	8b 45 d8             	mov    -0x28(%ebp),%eax
  80054a:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80054d:	f7 d8                	neg    %eax
  80054f:	83 d2 00             	adc    $0x0,%edx
  800552:	f7 da                	neg    %edx
  800554:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
  800557:	b9 0a 00 00 00       	mov    $0xa,%ecx
  80055c:	eb 55                	jmp    8005b3 <vprintfmt+0x311>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  80055e:	8d 45 14             	lea    0x14(%ebp),%eax
  800561:	e8 96 fc ff ff       	call   8001fc <getuint>
			base = 10;
  800566:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  80056b:	eb 46                	jmp    8005b3 <vprintfmt+0x311>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  80056d:	8d 45 14             	lea    0x14(%ebp),%eax
  800570:	e8 87 fc ff ff       	call   8001fc <getuint>
			base = 8;
  800575:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  80057a:	eb 37                	jmp    8005b3 <vprintfmt+0x311>

		// pointer
		case 'p':
			putch('0', putdat);
  80057c:	83 ec 08             	sub    $0x8,%esp
  80057f:	53                   	push   %ebx
  800580:	6a 30                	push   $0x30
  800582:	ff d6                	call   *%esi
			putch('x', putdat);
  800584:	83 c4 08             	add    $0x8,%esp
  800587:	53                   	push   %ebx
  800588:	6a 78                	push   $0x78
  80058a:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80058c:	8b 45 14             	mov    0x14(%ebp),%eax
  80058f:	8d 50 04             	lea    0x4(%eax),%edx
  800592:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800595:	8b 00                	mov    (%eax),%eax
  800597:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
  80059c:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80059f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8005a4:	eb 0d                	jmp    8005b3 <vprintfmt+0x311>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8005a6:	8d 45 14             	lea    0x14(%ebp),%eax
  8005a9:	e8 4e fc ff ff       	call   8001fc <getuint>
			base = 16;
  8005ae:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8005b3:	83 ec 0c             	sub    $0xc,%esp
  8005b6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
  8005ba:	57                   	push   %edi
  8005bb:	ff 75 e0             	pushl  -0x20(%ebp)
  8005be:	51                   	push   %ecx
  8005bf:	52                   	push   %edx
  8005c0:	50                   	push   %eax
  8005c1:	89 da                	mov    %ebx,%edx
  8005c3:	89 f0                	mov    %esi,%eax
  8005c5:	e8 83 fb ff ff       	call   80014d <printnum>
			break;
  8005ca:	83 c4 20             	add    $0x20,%esp
  8005cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
  8005d0:	e9 f3 fc ff ff       	jmp    8002c8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8005d5:	83 ec 08             	sub    $0x8,%esp
  8005d8:	53                   	push   %ebx
  8005d9:	51                   	push   %ecx
  8005da:	ff d6                	call   *%esi
			break;
  8005dc:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005df:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
  8005e2:	e9 e1 fc ff ff       	jmp    8002c8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8005e7:	83 ec 08             	sub    $0x8,%esp
  8005ea:	53                   	push   %ebx
  8005eb:	6a 25                	push   $0x25
  8005ed:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
  8005ef:	83 c4 10             	add    $0x10,%esp
  8005f2:	eb 03                	jmp    8005f7 <vprintfmt+0x355>
  8005f4:	83 ef 01             	sub    $0x1,%edi
  8005f7:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
  8005fb:	75 f7                	jne    8005f4 <vprintfmt+0x352>
  8005fd:	e9 c6 fc ff ff       	jmp    8002c8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
  800602:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800605:	5b                   	pop    %ebx
  800606:	5e                   	pop    %esi
  800607:	5f                   	pop    %edi
  800608:	5d                   	pop    %ebp
  800609:	c3                   	ret    

0080060a <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  80060a:	55                   	push   %ebp
  80060b:	89 e5                	mov    %esp,%ebp
  80060d:	83 ec 18             	sub    $0x18,%esp
  800610:	8b 45 08             	mov    0x8(%ebp),%eax
  800613:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  800616:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800619:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  80061d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800620:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  800627:	85 c0                	test   %eax,%eax
  800629:	74 26                	je     800651 <vsnprintf+0x47>
  80062b:	85 d2                	test   %edx,%edx
  80062d:	7e 22                	jle    800651 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  80062f:	ff 75 14             	pushl  0x14(%ebp)
  800632:	ff 75 10             	pushl  0x10(%ebp)
  800635:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800638:	50                   	push   %eax
  800639:	68 68 02 80 00       	push   $0x800268
  80063e:	e8 5f fc ff ff       	call   8002a2 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800643:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800646:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800649:	8b 45 f4             	mov    -0xc(%ebp),%eax
  80064c:	83 c4 10             	add    $0x10,%esp
  80064f:	eb 05                	jmp    800656 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800651:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800656:	c9                   	leave  
  800657:	c3                   	ret    

00800658 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800658:	55                   	push   %ebp
  800659:	89 e5                	mov    %esp,%ebp
  80065b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  80065e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800661:	50                   	push   %eax
  800662:	ff 75 10             	pushl  0x10(%ebp)
  800665:	ff 75 0c             	pushl  0xc(%ebp)
  800668:	ff 75 08             	pushl  0x8(%ebp)
  80066b:	e8 9a ff ff ff       	call   80060a <vsnprintf>
	va_end(ap);

	return rc;
}
  800670:	c9                   	leave  
  800671:	c3                   	ret    

00800672 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800672:	55                   	push   %ebp
  800673:	89 e5                	mov    %esp,%ebp
  800675:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800678:	b8 00 00 00 00       	mov    $0x0,%eax
  80067d:	eb 03                	jmp    800682 <strlen+0x10>
		n++;
  80067f:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800682:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800686:	75 f7                	jne    80067f <strlen+0xd>
		n++;
	return n;
}
  800688:	5d                   	pop    %ebp
  800689:	c3                   	ret    

0080068a <strnlen>:

int
strnlen(const char *s, size_t size)
{
  80068a:	55                   	push   %ebp
  80068b:	89 e5                	mov    %esp,%ebp
  80068d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800690:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800693:	ba 00 00 00 00       	mov    $0x0,%edx
  800698:	eb 03                	jmp    80069d <strnlen+0x13>
		n++;
  80069a:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80069d:	39 c2                	cmp    %eax,%edx
  80069f:	74 08                	je     8006a9 <strnlen+0x1f>
  8006a1:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
  8006a5:	75 f3                	jne    80069a <strnlen+0x10>
  8006a7:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
  8006a9:	5d                   	pop    %ebp
  8006aa:	c3                   	ret    

008006ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8006ab:	55                   	push   %ebp
  8006ac:	89 e5                	mov    %esp,%ebp
  8006ae:	53                   	push   %ebx
  8006af:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8006b5:	89 c2                	mov    %eax,%edx
  8006b7:	83 c2 01             	add    $0x1,%edx
  8006ba:	83 c1 01             	add    $0x1,%ecx
  8006bd:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8006c1:	88 5a ff             	mov    %bl,-0x1(%edx)
  8006c4:	84 db                	test   %bl,%bl
  8006c6:	75 ef                	jne    8006b7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8006c8:	5b                   	pop    %ebx
  8006c9:	5d                   	pop    %ebp
  8006ca:	c3                   	ret    

008006cb <strcat>:

char *
strcat(char *dst, const char *src)
{
  8006cb:	55                   	push   %ebp
  8006cc:	89 e5                	mov    %esp,%ebp
  8006ce:	53                   	push   %ebx
  8006cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8006d2:	53                   	push   %ebx
  8006d3:	e8 9a ff ff ff       	call   800672 <strlen>
  8006d8:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
  8006db:	ff 75 0c             	pushl  0xc(%ebp)
  8006de:	01 d8                	add    %ebx,%eax
  8006e0:	50                   	push   %eax
  8006e1:	e8 c5 ff ff ff       	call   8006ab <strcpy>
	return dst;
}
  8006e6:	89 d8                	mov    %ebx,%eax
  8006e8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
  8006eb:	c9                   	leave  
  8006ec:	c3                   	ret    

008006ed <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8006ed:	55                   	push   %ebp
  8006ee:	89 e5                	mov    %esp,%ebp
  8006f0:	56                   	push   %esi
  8006f1:	53                   	push   %ebx
  8006f2:	8b 75 08             	mov    0x8(%ebp),%esi
  8006f5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8006f8:	89 f3                	mov    %esi,%ebx
  8006fa:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8006fd:	89 f2                	mov    %esi,%edx
  8006ff:	eb 0f                	jmp    800710 <strncpy+0x23>
		*dst++ = *src;
  800701:	83 c2 01             	add    $0x1,%edx
  800704:	0f b6 01             	movzbl (%ecx),%eax
  800707:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80070a:	80 39 01             	cmpb   $0x1,(%ecx)
  80070d:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800710:	39 da                	cmp    %ebx,%edx
  800712:	75 ed                	jne    800701 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800714:	89 f0                	mov    %esi,%eax
  800716:	5b                   	pop    %ebx
  800717:	5e                   	pop    %esi
  800718:	5d                   	pop    %ebp
  800719:	c3                   	ret    

0080071a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80071a:	55                   	push   %ebp
  80071b:	89 e5                	mov    %esp,%ebp
  80071d:	56                   	push   %esi
  80071e:	53                   	push   %ebx
  80071f:	8b 75 08             	mov    0x8(%ebp),%esi
  800722:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800725:	8b 55 10             	mov    0x10(%ebp),%edx
  800728:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  80072a:	85 d2                	test   %edx,%edx
  80072c:	74 21                	je     80074f <strlcpy+0x35>
  80072e:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
  800732:	89 f2                	mov    %esi,%edx
  800734:	eb 09                	jmp    80073f <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800736:	83 c2 01             	add    $0x1,%edx
  800739:	83 c1 01             	add    $0x1,%ecx
  80073c:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  80073f:	39 c2                	cmp    %eax,%edx
  800741:	74 09                	je     80074c <strlcpy+0x32>
  800743:	0f b6 19             	movzbl (%ecx),%ebx
  800746:	84 db                	test   %bl,%bl
  800748:	75 ec                	jne    800736 <strlcpy+0x1c>
  80074a:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
  80074c:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  80074f:	29 f0                	sub    %esi,%eax
}
  800751:	5b                   	pop    %ebx
  800752:	5e                   	pop    %esi
  800753:	5d                   	pop    %ebp
  800754:	c3                   	ret    

00800755 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800755:	55                   	push   %ebp
  800756:	89 e5                	mov    %esp,%ebp
  800758:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80075b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  80075e:	eb 06                	jmp    800766 <strcmp+0x11>
		p++, q++;
  800760:	83 c1 01             	add    $0x1,%ecx
  800763:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800766:	0f b6 01             	movzbl (%ecx),%eax
  800769:	84 c0                	test   %al,%al
  80076b:	74 04                	je     800771 <strcmp+0x1c>
  80076d:	3a 02                	cmp    (%edx),%al
  80076f:	74 ef                	je     800760 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800771:	0f b6 c0             	movzbl %al,%eax
  800774:	0f b6 12             	movzbl (%edx),%edx
  800777:	29 d0                	sub    %edx,%eax
}
  800779:	5d                   	pop    %ebp
  80077a:	c3                   	ret    

0080077b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  80077b:	55                   	push   %ebp
  80077c:	89 e5                	mov    %esp,%ebp
  80077e:	53                   	push   %ebx
  80077f:	8b 45 08             	mov    0x8(%ebp),%eax
  800782:	8b 55 0c             	mov    0xc(%ebp),%edx
  800785:	89 c3                	mov    %eax,%ebx
  800787:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  80078a:	eb 06                	jmp    800792 <strncmp+0x17>
		n--, p++, q++;
  80078c:	83 c0 01             	add    $0x1,%eax
  80078f:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800792:	39 d8                	cmp    %ebx,%eax
  800794:	74 15                	je     8007ab <strncmp+0x30>
  800796:	0f b6 08             	movzbl (%eax),%ecx
  800799:	84 c9                	test   %cl,%cl
  80079b:	74 04                	je     8007a1 <strncmp+0x26>
  80079d:	3a 0a                	cmp    (%edx),%cl
  80079f:	74 eb                	je     80078c <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8007a1:	0f b6 00             	movzbl (%eax),%eax
  8007a4:	0f b6 12             	movzbl (%edx),%edx
  8007a7:	29 d0                	sub    %edx,%eax
  8007a9:	eb 05                	jmp    8007b0 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8007ab:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8007b0:	5b                   	pop    %ebx
  8007b1:	5d                   	pop    %ebp
  8007b2:	c3                   	ret    

008007b3 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8007b3:	55                   	push   %ebp
  8007b4:	89 e5                	mov    %esp,%ebp
  8007b6:	8b 45 08             	mov    0x8(%ebp),%eax
  8007b9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007bd:	eb 07                	jmp    8007c6 <strchr+0x13>
		if (*s == c)
  8007bf:	38 ca                	cmp    %cl,%dl
  8007c1:	74 0f                	je     8007d2 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8007c3:	83 c0 01             	add    $0x1,%eax
  8007c6:	0f b6 10             	movzbl (%eax),%edx
  8007c9:	84 d2                	test   %dl,%dl
  8007cb:	75 f2                	jne    8007bf <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8007cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8007d2:	5d                   	pop    %ebp
  8007d3:	c3                   	ret    

008007d4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8007d4:	55                   	push   %ebp
  8007d5:	89 e5                	mov    %esp,%ebp
  8007d7:	8b 45 08             	mov    0x8(%ebp),%eax
  8007da:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8007de:	eb 03                	jmp    8007e3 <strfind+0xf>
  8007e0:	83 c0 01             	add    $0x1,%eax
  8007e3:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
  8007e6:	38 ca                	cmp    %cl,%dl
  8007e8:	74 04                	je     8007ee <strfind+0x1a>
  8007ea:	84 d2                	test   %dl,%dl
  8007ec:	75 f2                	jne    8007e0 <strfind+0xc>
			break;
	return (char *) s;
}
  8007ee:	5d                   	pop    %ebp
  8007ef:	c3                   	ret    

008007f0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8007f0:	55                   	push   %ebp
  8007f1:	89 e5                	mov    %esp,%ebp
  8007f3:	57                   	push   %edi
  8007f4:	56                   	push   %esi
  8007f5:	53                   	push   %ebx
  8007f6:	8b 55 08             	mov    0x8(%ebp),%edx
  8007f9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p = v;

	if (n == 0)
  8007fc:	85 c9                	test   %ecx,%ecx
  8007fe:	74 37                	je     800837 <memset+0x47>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800800:	f6 c2 03             	test   $0x3,%dl
  800803:	75 2a                	jne    80082f <memset+0x3f>
  800805:	f6 c1 03             	test   $0x3,%cl
  800808:	75 25                	jne    80082f <memset+0x3f>
		c &= 0xFF;
  80080a:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  80080e:	89 df                	mov    %ebx,%edi
  800810:	c1 e7 08             	shl    $0x8,%edi
  800813:	89 de                	mov    %ebx,%esi
  800815:	c1 e6 18             	shl    $0x18,%esi
  800818:	89 d8                	mov    %ebx,%eax
  80081a:	c1 e0 10             	shl    $0x10,%eax
  80081d:	09 f0                	or     %esi,%eax
  80081f:	09 c3                	or     %eax,%ebx
		asm volatile("cld; rep stosl\n"
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
  800821:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800824:	89 f8                	mov    %edi,%eax
  800826:	09 d8                	or     %ebx,%eax
  800828:	89 d7                	mov    %edx,%edi
  80082a:	fc                   	cld    
  80082b:	f3 ab                	rep stos %eax,%es:(%edi)
  80082d:	eb 08                	jmp    800837 <memset+0x47>
			: "=D" (p), "=c" (n)
			: "D" (p), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  80082f:	89 d7                	mov    %edx,%edi
  800831:	8b 45 0c             	mov    0xc(%ebp),%eax
  800834:	fc                   	cld    
  800835:	f3 aa                	rep stos %al,%es:(%edi)
			: "=D" (p), "=c" (n)
			: "0" (p), "a" (c), "1" (n)
			: "cc", "memory");
	return v;
}
  800837:	89 d0                	mov    %edx,%eax
  800839:	5b                   	pop    %ebx
  80083a:	5e                   	pop    %esi
  80083b:	5f                   	pop    %edi
  80083c:	5d                   	pop    %ebp
  80083d:	c3                   	ret    

0080083e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  80083e:	55                   	push   %ebp
  80083f:	89 e5                	mov    %esp,%ebp
  800841:	57                   	push   %edi
  800842:	56                   	push   %esi
  800843:	8b 45 08             	mov    0x8(%ebp),%eax
  800846:	8b 75 0c             	mov    0xc(%ebp),%esi
  800849:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  80084c:	39 c6                	cmp    %eax,%esi
  80084e:	73 35                	jae    800885 <memmove+0x47>
  800850:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800853:	39 d0                	cmp    %edx,%eax
  800855:	73 2e                	jae    800885 <memmove+0x47>
		s += n;
		d += n;
  800857:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80085a:	89 d6                	mov    %edx,%esi
  80085c:	09 fe                	or     %edi,%esi
  80085e:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800864:	75 13                	jne    800879 <memmove+0x3b>
  800866:	f6 c1 03             	test   $0x3,%cl
  800869:	75 0e                	jne    800879 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
  80086b:	83 ef 04             	sub    $0x4,%edi
  80086e:	8d 72 fc             	lea    -0x4(%edx),%esi
  800871:	c1 e9 02             	shr    $0x2,%ecx
  800874:	fd                   	std    
  800875:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800877:	eb 09                	jmp    800882 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800879:	83 ef 01             	sub    $0x1,%edi
  80087c:	8d 72 ff             	lea    -0x1(%edx),%esi
  80087f:	fd                   	std    
  800880:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800882:	fc                   	cld    
  800883:	eb 1d                	jmp    8008a2 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800885:	89 f2                	mov    %esi,%edx
  800887:	09 c2                	or     %eax,%edx
  800889:	f6 c2 03             	test   $0x3,%dl
  80088c:	75 0f                	jne    80089d <memmove+0x5f>
  80088e:	f6 c1 03             	test   $0x3,%cl
  800891:	75 0a                	jne    80089d <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
  800893:	c1 e9 02             	shr    $0x2,%ecx
  800896:	89 c7                	mov    %eax,%edi
  800898:	fc                   	cld    
  800899:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80089b:	eb 05                	jmp    8008a2 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  80089d:	89 c7                	mov    %eax,%edi
  80089f:	fc                   	cld    
  8008a0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8008a2:	5e                   	pop    %esi
  8008a3:	5f                   	pop    %edi
  8008a4:	5d                   	pop    %ebp
  8008a5:	c3                   	ret    

008008a6 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8008a6:	55                   	push   %ebp
  8008a7:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
  8008a9:	ff 75 10             	pushl  0x10(%ebp)
  8008ac:	ff 75 0c             	pushl  0xc(%ebp)
  8008af:	ff 75 08             	pushl  0x8(%ebp)
  8008b2:	e8 87 ff ff ff       	call   80083e <memmove>
}
  8008b7:	c9                   	leave  
  8008b8:	c3                   	ret    

008008b9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8008b9:	55                   	push   %ebp
  8008ba:	89 e5                	mov    %esp,%ebp
  8008bc:	56                   	push   %esi
  8008bd:	53                   	push   %ebx
  8008be:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c1:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008c4:	89 c6                	mov    %eax,%esi
  8008c6:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008c9:	eb 1a                	jmp    8008e5 <memcmp+0x2c>
		if (*s1 != *s2)
  8008cb:	0f b6 08             	movzbl (%eax),%ecx
  8008ce:	0f b6 1a             	movzbl (%edx),%ebx
  8008d1:	38 d9                	cmp    %bl,%cl
  8008d3:	74 0a                	je     8008df <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8008d5:	0f b6 c1             	movzbl %cl,%eax
  8008d8:	0f b6 db             	movzbl %bl,%ebx
  8008db:	29 d8                	sub    %ebx,%eax
  8008dd:	eb 0f                	jmp    8008ee <memcmp+0x35>
		s1++, s2++;
  8008df:	83 c0 01             	add    $0x1,%eax
  8008e2:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8008e5:	39 f0                	cmp    %esi,%eax
  8008e7:	75 e2                	jne    8008cb <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8008e9:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008ee:	5b                   	pop    %ebx
  8008ef:	5e                   	pop    %esi
  8008f0:	5d                   	pop    %ebp
  8008f1:	c3                   	ret    

008008f2 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8008f2:	55                   	push   %ebp
  8008f3:	89 e5                	mov    %esp,%ebp
  8008f5:	53                   	push   %ebx
  8008f6:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
  8008f9:	89 c1                	mov    %eax,%ecx
  8008fb:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
  8008fe:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800902:	eb 0a                	jmp    80090e <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
  800904:	0f b6 10             	movzbl (%eax),%edx
  800907:	39 da                	cmp    %ebx,%edx
  800909:	74 07                	je     800912 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  80090b:	83 c0 01             	add    $0x1,%eax
  80090e:	39 c8                	cmp    %ecx,%eax
  800910:	72 f2                	jb     800904 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800912:	5b                   	pop    %ebx
  800913:	5d                   	pop    %ebp
  800914:	c3                   	ret    

00800915 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800915:	55                   	push   %ebp
  800916:	89 e5                	mov    %esp,%ebp
  800918:	57                   	push   %edi
  800919:	56                   	push   %esi
  80091a:	53                   	push   %ebx
  80091b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80091e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800921:	eb 03                	jmp    800926 <strtol+0x11>
		s++;
  800923:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800926:	0f b6 01             	movzbl (%ecx),%eax
  800929:	3c 20                	cmp    $0x20,%al
  80092b:	74 f6                	je     800923 <strtol+0xe>
  80092d:	3c 09                	cmp    $0x9,%al
  80092f:	74 f2                	je     800923 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800931:	3c 2b                	cmp    $0x2b,%al
  800933:	75 0a                	jne    80093f <strtol+0x2a>
		s++;
  800935:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800938:	bf 00 00 00 00       	mov    $0x0,%edi
  80093d:	eb 11                	jmp    800950 <strtol+0x3b>
  80093f:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800944:	3c 2d                	cmp    $0x2d,%al
  800946:	75 08                	jne    800950 <strtol+0x3b>
		s++, neg = 1;
  800948:	83 c1 01             	add    $0x1,%ecx
  80094b:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800950:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
  800956:	75 15                	jne    80096d <strtol+0x58>
  800958:	80 39 30             	cmpb   $0x30,(%ecx)
  80095b:	75 10                	jne    80096d <strtol+0x58>
  80095d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
  800961:	75 7c                	jne    8009df <strtol+0xca>
		s += 2, base = 16;
  800963:	83 c1 02             	add    $0x2,%ecx
  800966:	bb 10 00 00 00       	mov    $0x10,%ebx
  80096b:	eb 16                	jmp    800983 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
  80096d:	85 db                	test   %ebx,%ebx
  80096f:	75 12                	jne    800983 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800971:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800976:	80 39 30             	cmpb   $0x30,(%ecx)
  800979:	75 08                	jne    800983 <strtol+0x6e>
		s++, base = 8;
  80097b:	83 c1 01             	add    $0x1,%ecx
  80097e:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
  800983:	b8 00 00 00 00       	mov    $0x0,%eax
  800988:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  80098b:	0f b6 11             	movzbl (%ecx),%edx
  80098e:	8d 72 d0             	lea    -0x30(%edx),%esi
  800991:	89 f3                	mov    %esi,%ebx
  800993:	80 fb 09             	cmp    $0x9,%bl
  800996:	77 08                	ja     8009a0 <strtol+0x8b>
			dig = *s - '0';
  800998:	0f be d2             	movsbl %dl,%edx
  80099b:	83 ea 30             	sub    $0x30,%edx
  80099e:	eb 22                	jmp    8009c2 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
  8009a0:	8d 72 9f             	lea    -0x61(%edx),%esi
  8009a3:	89 f3                	mov    %esi,%ebx
  8009a5:	80 fb 19             	cmp    $0x19,%bl
  8009a8:	77 08                	ja     8009b2 <strtol+0x9d>
			dig = *s - 'a' + 10;
  8009aa:	0f be d2             	movsbl %dl,%edx
  8009ad:	83 ea 57             	sub    $0x57,%edx
  8009b0:	eb 10                	jmp    8009c2 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
  8009b2:	8d 72 bf             	lea    -0x41(%edx),%esi
  8009b5:	89 f3                	mov    %esi,%ebx
  8009b7:	80 fb 19             	cmp    $0x19,%bl
  8009ba:	77 16                	ja     8009d2 <strtol+0xbd>
			dig = *s - 'A' + 10;
  8009bc:	0f be d2             	movsbl %dl,%edx
  8009bf:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
  8009c2:	3b 55 10             	cmp    0x10(%ebp),%edx
  8009c5:	7d 0b                	jge    8009d2 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
  8009c7:	83 c1 01             	add    $0x1,%ecx
  8009ca:	0f af 45 10          	imul   0x10(%ebp),%eax
  8009ce:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
  8009d0:	eb b9                	jmp    80098b <strtol+0x76>

	if (endptr)
  8009d2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  8009d6:	74 0d                	je     8009e5 <strtol+0xd0>
		*endptr = (char *) s;
  8009d8:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009db:	89 0e                	mov    %ecx,(%esi)
  8009dd:	eb 06                	jmp    8009e5 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  8009df:	85 db                	test   %ebx,%ebx
  8009e1:	74 98                	je     80097b <strtol+0x66>
  8009e3:	eb 9e                	jmp    800983 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
  8009e5:	89 c2                	mov    %eax,%edx
  8009e7:	f7 da                	neg    %edx
  8009e9:	85 ff                	test   %edi,%edi
  8009eb:	0f 45 c2             	cmovne %edx,%eax
}
  8009ee:	5b                   	pop    %ebx
  8009ef:	5e                   	pop    %esi
  8009f0:	5f                   	pop    %edi
  8009f1:	5d                   	pop    %ebp
  8009f2:	c3                   	ret    

008009f3 <syscall>:
#include <inc/syscall.h>
#include <inc/lib.h>

static inline int32_t
syscall(int num, int check, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
  8009f3:	55                   	push   %ebp
  8009f4:	89 e5                	mov    %esp,%ebp
  8009f6:	57                   	push   %edi
  8009f7:	56                   	push   %esi
  8009f8:	53                   	push   %ebx
  8009f9:	83 ec 1c             	sub    $0x1c,%esp
  8009fc:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8009ff:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800a02:	89 ca                	mov    %ecx,%edx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800a04:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  800a0a:	8b 7d 10             	mov    0x10(%ebp),%edi
  800a0d:	8b 75 14             	mov    0x14(%ebp),%esi
  800a10:	cd 30                	int    $0x30
		       "b" (a3),
		       "D" (a4),
		       "S" (a5)
		     : "cc", "memory");

	if(check && ret > 0)
  800a12:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  800a16:	74 1d                	je     800a35 <syscall+0x42>
  800a18:	85 c0                	test   %eax,%eax
  800a1a:	7e 19                	jle    800a35 <syscall+0x42>
  800a1c:	8b 55 e0             	mov    -0x20(%ebp),%edx
		panic("syscall %d returned %d (> 0)", num, ret);
  800a1f:	83 ec 0c             	sub    $0xc,%esp
  800a22:	50                   	push   %eax
  800a23:	52                   	push   %edx
  800a24:	68 d4 0f 80 00       	push   $0x800fd4
  800a29:	6a 23                	push   $0x23
  800a2b:	68 f1 0f 80 00       	push   $0x800ff1
  800a30:	e8 98 00 00 00       	call   800acd <_panic>

	return ret;
}
  800a35:	8d 65 f4             	lea    -0xc(%ebp),%esp
  800a38:	5b                   	pop    %ebx
  800a39:	5e                   	pop    %esi
  800a3a:	5f                   	pop    %edi
  800a3b:	5d                   	pop    %ebp
  800a3c:	c3                   	ret    

00800a3d <sys_cputs>:

void
sys_cputs(const char *s, size_t len)
{
  800a3d:	55                   	push   %ebp
  800a3e:	89 e5                	mov    %esp,%ebp
  800a40:	83 ec 08             	sub    $0x8,%esp
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
  800a43:	6a 00                	push   $0x0
  800a45:	6a 00                	push   $0x0
  800a47:	6a 00                	push   $0x0
  800a49:	ff 75 0c             	pushl  0xc(%ebp)
  800a4c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a4f:	ba 00 00 00 00       	mov    $0x0,%edx
  800a54:	b8 00 00 00 00       	mov    $0x0,%eax
  800a59:	e8 95 ff ff ff       	call   8009f3 <syscall>
}
  800a5e:	83 c4 10             	add    $0x10,%esp
  800a61:	c9                   	leave  
  800a62:	c3                   	ret    

00800a63 <sys_cgetc>:

int
sys_cgetc(void)
{
  800a63:	55                   	push   %ebp
  800a64:	89 e5                	mov    %esp,%ebp
  800a66:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
  800a69:	6a 00                	push   $0x0
  800a6b:	6a 00                	push   $0x0
  800a6d:	6a 00                	push   $0x0
  800a6f:	6a 00                	push   $0x0
  800a71:	b9 00 00 00 00       	mov    $0x0,%ecx
  800a76:	ba 00 00 00 00       	mov    $0x0,%edx
  800a7b:	b8 01 00 00 00       	mov    $0x1,%eax
  800a80:	e8 6e ff ff ff       	call   8009f3 <syscall>
}
  800a85:	c9                   	leave  
  800a86:	c3                   	ret    

00800a87 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800a87:	55                   	push   %ebp
  800a88:	89 e5                	mov    %esp,%ebp
  800a8a:	83 ec 08             	sub    $0x8,%esp
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
  800a8d:	6a 00                	push   $0x0
  800a8f:	6a 00                	push   $0x0
  800a91:	6a 00                	push   $0x0
  800a93:	6a 00                	push   $0x0
  800a95:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a98:	ba 01 00 00 00       	mov    $0x1,%edx
  800a9d:	b8 03 00 00 00       	mov    $0x3,%eax
  800aa2:	e8 4c ff ff ff       	call   8009f3 <syscall>
}
  800aa7:	c9                   	leave  
  800aa8:	c3                   	ret    

00800aa9 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800aa9:	55                   	push   %ebp
  800aaa:	89 e5                	mov    %esp,%ebp
  800aac:	83 ec 08             	sub    $0x8,%esp
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
  800aaf:	6a 00                	push   $0x0
  800ab1:	6a 00                	push   $0x0
  800ab3:	6a 00                	push   $0x0
  800ab5:	6a 00                	push   $0x0
  800ab7:	b9 00 00 00 00       	mov    $0x0,%ecx
  800abc:	ba 00 00 00 00       	mov    $0x0,%edx
  800ac1:	b8 02 00 00 00       	mov    $0x2,%eax
  800ac6:	e8 28 ff ff ff       	call   8009f3 <syscall>
}
  800acb:	c9                   	leave  
  800acc:	c3                   	ret    

00800acd <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800acd:	55                   	push   %ebp
  800ace:	89 e5                	mov    %esp,%ebp
  800ad0:	56                   	push   %esi
  800ad1:	53                   	push   %ebx
	va_list ap;

	va_start(ap, fmt);
  800ad2:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800ad5:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800adb:	e8 c9 ff ff ff       	call   800aa9 <sys_getenvid>
  800ae0:	83 ec 0c             	sub    $0xc,%esp
  800ae3:	ff 75 0c             	pushl  0xc(%ebp)
  800ae6:	ff 75 08             	pushl  0x8(%ebp)
  800ae9:	56                   	push   %esi
  800aea:	50                   	push   %eax
  800aeb:	68 00 10 80 00       	push   $0x801000
  800af0:	e8 44 f6 ff ff       	call   800139 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800af5:	83 c4 18             	add    $0x18,%esp
  800af8:	53                   	push   %ebx
  800af9:	ff 75 10             	pushl  0x10(%ebp)
  800afc:	e8 e7 f5 ff ff       	call   8000e8 <vcprintf>
	cprintf("\n");
  800b01:	c7 04 24 b0 0d 80 00 	movl   $0x800db0,(%esp)
  800b08:	e8 2c f6 ff ff       	call   800139 <cprintf>
  800b0d:	83 c4 10             	add    $0x10,%esp

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800b10:	cc                   	int3   
  800b11:	eb fd                	jmp    800b10 <_panic+0x43>
  800b13:	66 90                	xchg   %ax,%ax
  800b15:	66 90                	xchg   %ax,%ax
  800b17:	66 90                	xchg   %ax,%ax
  800b19:	66 90                	xchg   %ax,%ax
  800b1b:	66 90                	xchg   %ax,%ax
  800b1d:	66 90                	xchg   %ax,%ax
  800b1f:	90                   	nop

00800b20 <__udivdi3>:
  800b20:	55                   	push   %ebp
  800b21:	57                   	push   %edi
  800b22:	56                   	push   %esi
  800b23:	53                   	push   %ebx
  800b24:	83 ec 1c             	sub    $0x1c,%esp
  800b27:	8b 74 24 3c          	mov    0x3c(%esp),%esi
  800b2b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
  800b2f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
  800b33:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800b37:	85 f6                	test   %esi,%esi
  800b39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800b3d:	89 ca                	mov    %ecx,%edx
  800b3f:	89 f8                	mov    %edi,%eax
  800b41:	75 3d                	jne    800b80 <__udivdi3+0x60>
  800b43:	39 cf                	cmp    %ecx,%edi
  800b45:	0f 87 c5 00 00 00    	ja     800c10 <__udivdi3+0xf0>
  800b4b:	85 ff                	test   %edi,%edi
  800b4d:	89 fd                	mov    %edi,%ebp
  800b4f:	75 0b                	jne    800b5c <__udivdi3+0x3c>
  800b51:	b8 01 00 00 00       	mov    $0x1,%eax
  800b56:	31 d2                	xor    %edx,%edx
  800b58:	f7 f7                	div    %edi
  800b5a:	89 c5                	mov    %eax,%ebp
  800b5c:	89 c8                	mov    %ecx,%eax
  800b5e:	31 d2                	xor    %edx,%edx
  800b60:	f7 f5                	div    %ebp
  800b62:	89 c1                	mov    %eax,%ecx
  800b64:	89 d8                	mov    %ebx,%eax
  800b66:	89 cf                	mov    %ecx,%edi
  800b68:	f7 f5                	div    %ebp
  800b6a:	89 c3                	mov    %eax,%ebx
  800b6c:	89 d8                	mov    %ebx,%eax
  800b6e:	89 fa                	mov    %edi,%edx
  800b70:	83 c4 1c             	add    $0x1c,%esp
  800b73:	5b                   	pop    %ebx
  800b74:	5e                   	pop    %esi
  800b75:	5f                   	pop    %edi
  800b76:	5d                   	pop    %ebp
  800b77:	c3                   	ret    
  800b78:	90                   	nop
  800b79:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800b80:	39 ce                	cmp    %ecx,%esi
  800b82:	77 74                	ja     800bf8 <__udivdi3+0xd8>
  800b84:	0f bd fe             	bsr    %esi,%edi
  800b87:	83 f7 1f             	xor    $0x1f,%edi
  800b8a:	0f 84 98 00 00 00    	je     800c28 <__udivdi3+0x108>
  800b90:	bb 20 00 00 00       	mov    $0x20,%ebx
  800b95:	89 f9                	mov    %edi,%ecx
  800b97:	89 c5                	mov    %eax,%ebp
  800b99:	29 fb                	sub    %edi,%ebx
  800b9b:	d3 e6                	shl    %cl,%esi
  800b9d:	89 d9                	mov    %ebx,%ecx
  800b9f:	d3 ed                	shr    %cl,%ebp
  800ba1:	89 f9                	mov    %edi,%ecx
  800ba3:	d3 e0                	shl    %cl,%eax
  800ba5:	09 ee                	or     %ebp,%esi
  800ba7:	89 d9                	mov    %ebx,%ecx
  800ba9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800bad:	89 d5                	mov    %edx,%ebp
  800baf:	8b 44 24 08          	mov    0x8(%esp),%eax
  800bb3:	d3 ed                	shr    %cl,%ebp
  800bb5:	89 f9                	mov    %edi,%ecx
  800bb7:	d3 e2                	shl    %cl,%edx
  800bb9:	89 d9                	mov    %ebx,%ecx
  800bbb:	d3 e8                	shr    %cl,%eax
  800bbd:	09 c2                	or     %eax,%edx
  800bbf:	89 d0                	mov    %edx,%eax
  800bc1:	89 ea                	mov    %ebp,%edx
  800bc3:	f7 f6                	div    %esi
  800bc5:	89 d5                	mov    %edx,%ebp
  800bc7:	89 c3                	mov    %eax,%ebx
  800bc9:	f7 64 24 0c          	mull   0xc(%esp)
  800bcd:	39 d5                	cmp    %edx,%ebp
  800bcf:	72 10                	jb     800be1 <__udivdi3+0xc1>
  800bd1:	8b 74 24 08          	mov    0x8(%esp),%esi
  800bd5:	89 f9                	mov    %edi,%ecx
  800bd7:	d3 e6                	shl    %cl,%esi
  800bd9:	39 c6                	cmp    %eax,%esi
  800bdb:	73 07                	jae    800be4 <__udivdi3+0xc4>
  800bdd:	39 d5                	cmp    %edx,%ebp
  800bdf:	75 03                	jne    800be4 <__udivdi3+0xc4>
  800be1:	83 eb 01             	sub    $0x1,%ebx
  800be4:	31 ff                	xor    %edi,%edi
  800be6:	89 d8                	mov    %ebx,%eax
  800be8:	89 fa                	mov    %edi,%edx
  800bea:	83 c4 1c             	add    $0x1c,%esp
  800bed:	5b                   	pop    %ebx
  800bee:	5e                   	pop    %esi
  800bef:	5f                   	pop    %edi
  800bf0:	5d                   	pop    %ebp
  800bf1:	c3                   	ret    
  800bf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800bf8:	31 ff                	xor    %edi,%edi
  800bfa:	31 db                	xor    %ebx,%ebx
  800bfc:	89 d8                	mov    %ebx,%eax
  800bfe:	89 fa                	mov    %edi,%edx
  800c00:	83 c4 1c             	add    $0x1c,%esp
  800c03:	5b                   	pop    %ebx
  800c04:	5e                   	pop    %esi
  800c05:	5f                   	pop    %edi
  800c06:	5d                   	pop    %ebp
  800c07:	c3                   	ret    
  800c08:	90                   	nop
  800c09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c10:	89 d8                	mov    %ebx,%eax
  800c12:	f7 f7                	div    %edi
  800c14:	31 ff                	xor    %edi,%edi
  800c16:	89 c3                	mov    %eax,%ebx
  800c18:	89 d8                	mov    %ebx,%eax
  800c1a:	89 fa                	mov    %edi,%edx
  800c1c:	83 c4 1c             	add    $0x1c,%esp
  800c1f:	5b                   	pop    %ebx
  800c20:	5e                   	pop    %esi
  800c21:	5f                   	pop    %edi
  800c22:	5d                   	pop    %ebp
  800c23:	c3                   	ret    
  800c24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c28:	39 ce                	cmp    %ecx,%esi
  800c2a:	72 0c                	jb     800c38 <__udivdi3+0x118>
  800c2c:	31 db                	xor    %ebx,%ebx
  800c2e:	3b 44 24 08          	cmp    0x8(%esp),%eax
  800c32:	0f 87 34 ff ff ff    	ja     800b6c <__udivdi3+0x4c>
  800c38:	bb 01 00 00 00       	mov    $0x1,%ebx
  800c3d:	e9 2a ff ff ff       	jmp    800b6c <__udivdi3+0x4c>
  800c42:	66 90                	xchg   %ax,%ax
  800c44:	66 90                	xchg   %ax,%ax
  800c46:	66 90                	xchg   %ax,%ax
  800c48:	66 90                	xchg   %ax,%ax
  800c4a:	66 90                	xchg   %ax,%ax
  800c4c:	66 90                	xchg   %ax,%ax
  800c4e:	66 90                	xchg   %ax,%ax

00800c50 <__umoddi3>:
  800c50:	55                   	push   %ebp
  800c51:	57                   	push   %edi
  800c52:	56                   	push   %esi
  800c53:	53                   	push   %ebx
  800c54:	83 ec 1c             	sub    $0x1c,%esp
  800c57:	8b 54 24 3c          	mov    0x3c(%esp),%edx
  800c5b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  800c5f:	8b 74 24 34          	mov    0x34(%esp),%esi
  800c63:	8b 7c 24 38          	mov    0x38(%esp),%edi
  800c67:	85 d2                	test   %edx,%edx
  800c69:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800c6d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800c71:	89 f3                	mov    %esi,%ebx
  800c73:	89 3c 24             	mov    %edi,(%esp)
  800c76:	89 74 24 04          	mov    %esi,0x4(%esp)
  800c7a:	75 1c                	jne    800c98 <__umoddi3+0x48>
  800c7c:	39 f7                	cmp    %esi,%edi
  800c7e:	76 50                	jbe    800cd0 <__umoddi3+0x80>
  800c80:	89 c8                	mov    %ecx,%eax
  800c82:	89 f2                	mov    %esi,%edx
  800c84:	f7 f7                	div    %edi
  800c86:	89 d0                	mov    %edx,%eax
  800c88:	31 d2                	xor    %edx,%edx
  800c8a:	83 c4 1c             	add    $0x1c,%esp
  800c8d:	5b                   	pop    %ebx
  800c8e:	5e                   	pop    %esi
  800c8f:	5f                   	pop    %edi
  800c90:	5d                   	pop    %ebp
  800c91:	c3                   	ret    
  800c92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800c98:	39 f2                	cmp    %esi,%edx
  800c9a:	89 d0                	mov    %edx,%eax
  800c9c:	77 52                	ja     800cf0 <__umoddi3+0xa0>
  800c9e:	0f bd ea             	bsr    %edx,%ebp
  800ca1:	83 f5 1f             	xor    $0x1f,%ebp
  800ca4:	75 5a                	jne    800d00 <__umoddi3+0xb0>
  800ca6:	3b 54 24 04          	cmp    0x4(%esp),%edx
  800caa:	0f 82 e0 00 00 00    	jb     800d90 <__umoddi3+0x140>
  800cb0:	39 0c 24             	cmp    %ecx,(%esp)
  800cb3:	0f 86 d7 00 00 00    	jbe    800d90 <__umoddi3+0x140>
  800cb9:	8b 44 24 08          	mov    0x8(%esp),%eax
  800cbd:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cc1:	83 c4 1c             	add    $0x1c,%esp
  800cc4:	5b                   	pop    %ebx
  800cc5:	5e                   	pop    %esi
  800cc6:	5f                   	pop    %edi
  800cc7:	5d                   	pop    %ebp
  800cc8:	c3                   	ret    
  800cc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800cd0:	85 ff                	test   %edi,%edi
  800cd2:	89 fd                	mov    %edi,%ebp
  800cd4:	75 0b                	jne    800ce1 <__umoddi3+0x91>
  800cd6:	b8 01 00 00 00       	mov    $0x1,%eax
  800cdb:	31 d2                	xor    %edx,%edx
  800cdd:	f7 f7                	div    %edi
  800cdf:	89 c5                	mov    %eax,%ebp
  800ce1:	89 f0                	mov    %esi,%eax
  800ce3:	31 d2                	xor    %edx,%edx
  800ce5:	f7 f5                	div    %ebp
  800ce7:	89 c8                	mov    %ecx,%eax
  800ce9:	f7 f5                	div    %ebp
  800ceb:	89 d0                	mov    %edx,%eax
  800ced:	eb 99                	jmp    800c88 <__umoddi3+0x38>
  800cef:	90                   	nop
  800cf0:	89 c8                	mov    %ecx,%eax
  800cf2:	89 f2                	mov    %esi,%edx
  800cf4:	83 c4 1c             	add    $0x1c,%esp
  800cf7:	5b                   	pop    %ebx
  800cf8:	5e                   	pop    %esi
  800cf9:	5f                   	pop    %edi
  800cfa:	5d                   	pop    %ebp
  800cfb:	c3                   	ret    
  800cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d00:	8b 34 24             	mov    (%esp),%esi
  800d03:	bf 20 00 00 00       	mov    $0x20,%edi
  800d08:	89 e9                	mov    %ebp,%ecx
  800d0a:	29 ef                	sub    %ebp,%edi
  800d0c:	d3 e0                	shl    %cl,%eax
  800d0e:	89 f9                	mov    %edi,%ecx
  800d10:	89 f2                	mov    %esi,%edx
  800d12:	d3 ea                	shr    %cl,%edx
  800d14:	89 e9                	mov    %ebp,%ecx
  800d16:	09 c2                	or     %eax,%edx
  800d18:	89 d8                	mov    %ebx,%eax
  800d1a:	89 14 24             	mov    %edx,(%esp)
  800d1d:	89 f2                	mov    %esi,%edx
  800d1f:	d3 e2                	shl    %cl,%edx
  800d21:	89 f9                	mov    %edi,%ecx
  800d23:	89 54 24 04          	mov    %edx,0x4(%esp)
  800d27:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d2b:	d3 e8                	shr    %cl,%eax
  800d2d:	89 e9                	mov    %ebp,%ecx
  800d2f:	89 c6                	mov    %eax,%esi
  800d31:	d3 e3                	shl    %cl,%ebx
  800d33:	89 f9                	mov    %edi,%ecx
  800d35:	89 d0                	mov    %edx,%eax
  800d37:	d3 e8                	shr    %cl,%eax
  800d39:	89 e9                	mov    %ebp,%ecx
  800d3b:	09 d8                	or     %ebx,%eax
  800d3d:	89 d3                	mov    %edx,%ebx
  800d3f:	89 f2                	mov    %esi,%edx
  800d41:	f7 34 24             	divl   (%esp)
  800d44:	89 d6                	mov    %edx,%esi
  800d46:	d3 e3                	shl    %cl,%ebx
  800d48:	f7 64 24 04          	mull   0x4(%esp)
  800d4c:	39 d6                	cmp    %edx,%esi
  800d4e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800d52:	89 d1                	mov    %edx,%ecx
  800d54:	89 c3                	mov    %eax,%ebx
  800d56:	72 08                	jb     800d60 <__umoddi3+0x110>
  800d58:	75 11                	jne    800d6b <__umoddi3+0x11b>
  800d5a:	39 44 24 08          	cmp    %eax,0x8(%esp)
  800d5e:	73 0b                	jae    800d6b <__umoddi3+0x11b>
  800d60:	2b 44 24 04          	sub    0x4(%esp),%eax
  800d64:	1b 14 24             	sbb    (%esp),%edx
  800d67:	89 d1                	mov    %edx,%ecx
  800d69:	89 c3                	mov    %eax,%ebx
  800d6b:	8b 54 24 08          	mov    0x8(%esp),%edx
  800d6f:	29 da                	sub    %ebx,%edx
  800d71:	19 ce                	sbb    %ecx,%esi
  800d73:	89 f9                	mov    %edi,%ecx
  800d75:	89 f0                	mov    %esi,%eax
  800d77:	d3 e0                	shl    %cl,%eax
  800d79:	89 e9                	mov    %ebp,%ecx
  800d7b:	d3 ea                	shr    %cl,%edx
  800d7d:	89 e9                	mov    %ebp,%ecx
  800d7f:	d3 ee                	shr    %cl,%esi
  800d81:	09 d0                	or     %edx,%eax
  800d83:	89 f2                	mov    %esi,%edx
  800d85:	83 c4 1c             	add    $0x1c,%esp
  800d88:	5b                   	pop    %ebx
  800d89:	5e                   	pop    %esi
  800d8a:	5f                   	pop    %edi
  800d8b:	5d                   	pop    %ebp
  800d8c:	c3                   	ret    
  800d8d:	8d 76 00             	lea    0x0(%esi),%esi
  800d90:	29 f9                	sub    %edi,%ecx
  800d92:	19 d6                	sbb    %edx,%esi
  800d94:	89 74 24 04          	mov    %esi,0x4(%esp)
  800d98:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d9c:	e9 18 ff ff ff       	jmp    800cb9 <__umoddi3+0x69>
